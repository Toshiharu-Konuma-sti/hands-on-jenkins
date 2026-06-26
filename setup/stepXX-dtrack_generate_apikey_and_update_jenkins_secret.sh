#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/common.sh
. ${CUR_DIR}/custom.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

# =====================================================================
# 1. Dependency-Track から Administrators の新しい API Key を発行・取得
# =====================================================================
echo "\n### START: get Dependency-Track admin token"
ACCESS_TOKEN=$(get_dtrack_access_token "${DTRK_HOST_API}" "${DTRK_ADMIN_USER}" "${DTRK_ADMIN_PASS}")


get_dtrack_team_api_key()
{
	DT_HOST=$1
	DT_TOKEN=$2
	DT_TEAM=$3

	CMD_TEAM="curl -s -X GET
		-H \"Authorization: Bearer ${DT_TOKEN}\"
		\"http://${DT_HOST}/api/v1/team\""
	BODY_TEAM=$(loop_curl_until_success "${CMD_TEAM}")

	TEAM_UUID=$(echo "${BODY_TEAM}" | jq -r ".[] | select(.name==\"${DT_TEAM}\") | .uuid")

	CMD_API_KEY="curl -s -X PUT
		-H \"Authorization: Bearer ${DT_TOKEN}\"
		\"http://${DT_HOST}/api/v1/team/${TEAM_UUID}/key\""
	BODY_API_KEY=$(loop_curl_until_success "${CMD_API_KEY}")
	API_KEY=$(echo "${BODY_API_KEY}" | jq -r '.key')

	echo "${API_KEY}"
}

echo "\n### START: get new Team API Key"
TEAM_NAME="Administrators"
API_KEY=$(get_dtrack_team_api_key "${DTRK_HOST_API}" "${ACCESS_TOKEN}" "${TEAM_NAME}")
echo "Generated ${DT_TEAM} API Key: ${API_KEY}"

# =====================================================================
# 2. Jenkins の認証情報をメモリ（環境変数）のみで取得（ファイル生成なし）
# =====================================================================
echo "\n### START: connect to Jenkins and fetch CSRF Crumb & Cookie into memory"

CMD_CRUMB="curl -v -i
	-u \"${JENK_USER}:${JENK_PASS}\"
	\"http://${JENK_HOST_EXT}/crumbIssuer/api/json\""
RAW_RESP_CRUMB=$(loop_curl_until_success "${CMD_CRUMB}")

JENK_COOKIE=$(echo "${RAW_RESP_CRUMB}" | awk '/^[Ss]et-[Cc]ookie:/ {print $2}' | tr -d ';')
JSON_CRUMB=$(echo "${RAW_RESP_CRUMB}" | tail -n 1)
CRUMB_FIELD=$(echo "${JSON_CRUMB}" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "${JSON_CRUMB}" | jq -r '.crumb')

echo ">>> RESULT >>>"
echo "${JSON_CRUMB}"
echo "${JENK_COOKIE}"
echo "${CRUMB_FIELD}"
echo "${CRUMB_VALUE}"
echo "<<< RESULT <<<"

# =====================================================================
# 3. 公式 Credentials REST API を使い、XMLを流し込んで上書き更新
# =====================================================================
echo "\n### START: update Jenkins credential via official Credentials REST API"

CRED_XML="<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl plugin='plain-credentials'>
  <scope>GLOBAL</scope>
  <id>dependency-track-api-key</id>
  <description>Dependency-Track API Key for Hands-on</description>
  <secret>${API_KEY}</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>"

CMD_CRED="curl -v -X POST
	-u \"${JENK_USER}:${JENK_PASS}\"
	-H \"Cookie: ${JENK_COOKIE}\"
	-H \"${CRUMB_FIELD}: ${CRUMB_VALUE}\"
	-H \"Content-Type: application/xml\"
	-d \"${CRED_XML}\"
	\"http://${JENK_HOST_EXT}/credentials/store/system/domain/_/credential/dependency-track-api-key/config.xml\""
BODY_CRED=$(loop_curl_until_success "${CMD_CRED}")

call_show_finish_banner
