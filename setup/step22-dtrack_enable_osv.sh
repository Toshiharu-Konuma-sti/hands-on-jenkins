#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/common.sh
. ${CUR_DIR}/custom.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: get admin's bearer token"

ACCESS_TOKEN=$(get_dtrack_access_token "${DTRK_HOST_API}" "${DTRK_ADMIN_USER}" "${DTRK_ADMIN_PASS}")

echo "\n### START: enable OSV (Maven only) via Extensions API v2"

CMD_OSV="curl -v -X PUT
	-H \"Content-Type: application/json\"
	-H \"Authorization: Bearer ${ACCESS_TOKEN}\"
	-d '{
  \"config\": {
    \"enabled\": true,
    \"ecosystems\": [\"Maven\"],
    \"dataUrl\": \"https://storage.googleapis.com/osv-vulnerabilities\",
    \"aliasSyncEnabled\": false,
    \"incrementalMirroringEnabled\": true
  }
}'
	\"http://localhost:${DTRK_APIS_PORT_AFT}/api/v2/extension-points/vuln-data-source/extensions/osv/config\""

BODY_OSV=$(loop_curl_until_success "${CMD_OSV}")

echo "\n### START: trigger OSV mirror run"

CMD_MIRROR="curl -v -X POST
	-H \"Authorization: Bearer ${ACCESS_TOKEN}\"
	\"http://localhost:${DTRK_APIS_PORT_AFT}/api/v2/vuln-data-sources/osv/mirror-runs\""

BODY_MIRROR=$(loop_curl_until_success "${CMD_MIRROR}")

call_show_finish_banner
