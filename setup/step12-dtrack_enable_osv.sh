#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/common.sh
. ${CUR_DIR}/custom.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: get admin's bearer token"

CMD_TOKEN="curl -v -X POST
	-H \"Content-Type: application/x-www-form-urlencoded\"
	-d \"username=${DTRK_ADMIN_USER}\"
	-d \"password=${DTRK_ADMIN_PASS}\"
	\"http://localhost:${DTRK_APIS_PORT_AFT}/api/v1/user/login\""
BODY_TOKEN=$(loop_curl_until_success "${CMD_TOKEN}")

# =====================================================================
# Dependency-Track v5 (Hyades) における OSV 設定:
#
# DT v5 では OSV の有効化・エコシステム設定は Extensions API v2 で行う。
#   エンドポイント: PUT /api/v2/extension-points/vuln-data-source/extensions/osv/config
#   リクエストボディ (JSON):
#     enabled                   : true/false
#     ecosystems                : 有効にするエコシステムの配列
#     dataUrl                   : OSV データダウンロード URL
#     aliasSyncEnabled          : エイリアス情報を含めるか
#     incrementalMirroringEnabled: 差分ミラーリングを使用するか
# =====================================================================

echo "\n### START: enable OSV (Maven only) via Extensions API v2"
echo "(extension-point=vuln-data-source, extension=osv)"

CMD_OSV="curl -v -X PUT
	-H \"Content-Type: application/json\"
	-H \"Authorization: Bearer ${BODY_TOKEN}\"
	-d '{\"config\":{\"enabled\":true,\"ecosystems\":[\"Maven\"],\"dataUrl\":\"https://storage.googleapis.com/osv-vulnerabilities\",\"aliasSyncEnabled\":false,\"incrementalMirroringEnabled\":true}}'
	\"http://localhost:${DTRK_APIS_PORT_AFT}/api/v2/extension-points/vuln-data-source/extensions/osv/config\""

echo ">>> CMD >>>"
echo "${CMD_OSV}"
echo "<<< CMD <<<\n\n"

BODY_OSV=$(loop_curl_until_success "${CMD_OSV}")
echo ">>> RESULT >>>"
echo "${BODY_OSV}"
echo "<<< RESULT <<<\n\n"

echo "\n### START: trigger OSV mirror run"
CMD_MIRROR="curl -v -X POST
	-H \"Authorization: Bearer ${BODY_TOKEN}\"
	\"http://localhost:${DTRK_APIS_PORT_AFT}/api/v2/vuln-data-sources/osv/mirror-runs\""

echo ">>> CMD >>>"
echo "${CMD_MIRROR}"
echo "<<< CMD <<<\n\n"

BODY_MIRROR=$(loop_curl_until_success "${CMD_MIRROR}")
echo ">>> RESULT >>>"
echo "${BODY_MIRROR}"
echo "<<< RESULT <<<\n\n"




call_show_finish_banner
