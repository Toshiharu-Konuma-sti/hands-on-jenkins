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
ACCESS_TOKEN=$(get_dtrack_access_token "${DTRK_ADMIN_USER}" "${DTRK_ADMIN_PASS}" "${DTRK_HOST_API}")

echo "\n### START: get UUID for Administrators team"
CMD_TEAM="curl -s -X GET \
        -H \"Authorization: Bearer ${ACCESS_TOKEN}\" \
        \"http://${DTRK_HOST_API}/api/v1/team\""
BODY_TEAM=$(loop_curl_until_success "${CMD_TEAM}")

# Administrators チームの UUID を抽出
TEAM_UUID=$(echo "${BODY_TEAM}" | jq -r '.[] | select(.name=="Administrators") | .uuid')
echo "Found Administrators UUID: ${TEAM_UUID}"

echo "\n### START: generate new API Key for Administrators"
CMD_API_KEY="curl -s -X PUT \
        -H \"Authorization: Bearer ${ACCESS_TOKEN}\" \
        \"http://${DTRK_HOST_API}/api/v1/team/${TEAM_UUID}/key\""
BODY_API_KEY=$(loop_curl_until_success "${CMD_API_KEY}")

# 生成された生の API Key を抽出
API_KEY=$(echo "${BODY_API_KEY}" | jq -r '.key')
echo "Generated Administrators API Key: ${API_KEY}"

# =====================================================================
# 2. Jenkins の認証情報をメモリ（環境変数）のみで取得（ファイル生成なし）
# =====================================================================
echo "\n### START: connect to Jenkins and fetch CSRF Crumb & Cookie into memory"

# -i オプションで HTTP ヘッダー（Set-Cookie）とレスポンスボディ（JSON）を同時に1つの変数に格納
RAW_RESPONSE=$(curl -s -i -u "${JENK_USER}:${JENK_PASS}" "http://${JENK_HOST_EXT}/crumbIssuer/api/json")
echo ">>> RESULT >>>"
echo "${RAW_RESPONSE}"
echo "<<< RESULT <<<"

# HTTP ヘッダーから「Set-Cookie:」の行を探し、Cookieの値（名=値）だけを抽出
# 例: "JSESSIONID.xxxx=yyyy"
JENK_COOKIE=$(echo "${RAW_RESPONSE}" | awk '/^[Ss]et-[Cc]ookie:/ {print $2}' | tr -d ';')
echo ">>> RESULT >>>"
echo "${JENK_COOKIE}"
echo "<<< RESULT <<<"

# HTTPヘッダー（最初の空行まで）を削ぎ落として、純粋なレスポンスボディ（JSON）だけを切り出す
# ※Mac(Darwin)の sed や Alpine(BusyBox)の sed でも共通で動くポータブルな記述
JSON_BODY=$(echo "${RAW_RESPONSE}" | tail -n 1)
echo ">>> RESULT >>>"
echo "${JSON_BODY}"
echo "<<< RESULT <<<"

# JSONから Crumb 情報を抽出
CRUMB_FIELD=$(echo "${JSON_BODY}" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "${JSON_BODY}" | jq -r '.crumb')
echo ">>> RESULT >>>"
echo "${CRUMB_FIELD}"
echo "${CRUMB_VALUE}"
echo "<<< RESULT <<<"

# =====================================================================
# 3. 公式 Credentials REST API を使い、XMLを流し込んで上書き更新
# =====================================================================
echo "\n### START: update Jenkins credential via official Credentials REST API"

CRED_XML="<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl plugin=\"plain-credentials\">
  <scope>GLOBAL</scope>
  <id>dependency-track-api-key</id>
  <description>Dependency-Track API Key for Hands-on</description>
  <secret>${API_KEY}</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>"

# ファイル（-b）の代わりに、標準の HTTP ヘッダー（-H "Cookie: ..."）としてメモリから直接流し込む
BODY_JENKINS=$(curl -v -X POST -u "${JENK_USER}:${JENK_PASS}" \
        -H "Cookie: ${JENK_COOKIE}" \
        -H "${CRUMB_FIELD}: ${CRUMB_VALUE}" \
        -H "Content-Type: application/xml" \
        -d "${CRED_XML}" \
        "http://${JENK_HOST_EXT}/credentials/store/system/domain/_/credential/dependency-track-api-key/config.xml")

echo ">>> JENKINS RESPONSE >>>"
if [ -z "$BODY_JENKINS" ]; then
        echo "SUCCESS: Jenkins credential has been updated via official XML configuration endpoint (Zero-File System)."
else
        echo "${BODY_JENKINS}"
fi
echo "<<< JENKINS RESPONSE <<<"

call_show_finish_banner
