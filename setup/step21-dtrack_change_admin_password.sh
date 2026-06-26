#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/common.sh
. ${CUR_DIR}/custom.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: change admin's initial password"

CMD_PASS="curl -v -X POST
	-H \"Content-Type: application/x-www-form-urlencoded\"
	-d \"username=${DTRK_ADMIN_USER}\"
	-d \"password=${DTRK_ADMIN_USER}\"
	-d \"newPassword=${DTRK_ADMIN_PASS}\"
	-d \"confirmPassword=${DTRK_ADMIN_PASS}\"
	\"http://localhost:${DTRK_APIS_PORT_AFT}/api/v1/user/forceChangePassword\""

DT_BODY=$(loop_curl_until_success "${CMD_PASS}")

call_show_finish_banner
