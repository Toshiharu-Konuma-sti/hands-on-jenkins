#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/common.sh
. ${CUR_DIR}/custom.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab"

GL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab"

GL_TOKEN=$(get_gitlab_access_token "${GITL_USER}" "${GL_PASS}" "${GITL_HOST}")

echo "\n### START: import CI/CD variables to GitLab repositories"

for MY_PROJ in ${WEBAPP_PROJECTS}; do

	CURL_CMD="curl -v -f -X POST
		\"http://${GITL_HOST}/api/v4/projects/${GITL_USER}%2F${MY_PROJ}/variables\"
		-H \"Authorization: Bearer ${GL_TOKEN}\"
		-H \"Content-Type: application/json\""

	echo ">>> importing ANSIBLE_SERVER_HOST..."
	CMD_VAR="${CURL_CMD}
		-d \"{
  \\\"key\\\": \\\"ANSIBLE_SERVER_HOST\\\",
  \\\"value\\\": \\\"${ANSIBLE_HOST}\\\",
  \\\"protected\\\": false,
  \\\"masked\\\": false
}\""
	GL_BODY=$(loop_curl_until_success "${CMD_VAR}")

	echo ">>> importing ANSIBLE_SERVER_USER..."
	CMD_VAR="${CURL_CMD}
		-d \"{
  \\\"key\\\": \\\"ANSIBLE_SERVER_USER\\\",
  \\\"value\\\": \\\"${ANSIBLE_USER}\\\",
  \\\"protected\\\": false,
  \\\"masked\\\": false
}\""
	GL_BODY=$(loop_curl_until_success "${CMD_VAR}")

	echo ">>> importing ANSIBLE_SERVER_PASSWORD..."
	CMD_VAR="${CURL_CMD}
		-d \"{
  \\\"key\\\": \\\"ANSIBLE_SERVER_PASSWORD\\\",
  \\\"value\\\": \\\"${ANSIBLE_PASS}\\\",
  \\\"protected\\\": false,
  \\\"masked\\\": true
}\""
	GL_BODY=$(loop_curl_until_success "${CMD_VAR}")

done

call_show_finish_banner
