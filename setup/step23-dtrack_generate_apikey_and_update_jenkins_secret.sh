#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/common.sh
. ${CUR_DIR}/custom.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

DTRK_TEAM="Administrators"

# =====================================================================
# 1. Get new API Key from Dependency-Track
# =====================================================================
echo "\n### START: get Dependency-Track admin token"
ACCESS_TOKEN=$(get_dtrack_access_token "${DTRK_HOST_API}" "${DTRK_ADMIN_USER}" "${DTRK_ADMIN_PASS}")

echo "\n### START: get new API Key for ${DTRK_TEAM} team"
API_KEY=$(get_dtrack_team_api_key "${DTRK_HOST_API}" "${ACCESS_TOKEN}" "${DTRK_TEAM}")
echo "Generated ${DTRK_TEAM} API Key: ${API_KEY}"

# =====================================================================
# 2. Get a credential for Jenkins
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

# =====================================================================
# 3. Update a secret for Dependency-Track in Jenkins
# =====================================================================
echo "\n### START: update a secret in Jenkins"

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
