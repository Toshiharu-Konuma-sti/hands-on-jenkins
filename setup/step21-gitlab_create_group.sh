#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/functions.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab"

GL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab"

GL_TOKEN=$(get_gitlab_access_token "${GITL_USER}" "${GL_PASS}" "${GITL_HOST}")

echo "\n### START: create a group"

GROUP_NAME="My Hands-on Group"
GROUP_PATH="my-hands-on-group"
VISIBILITY="public"

CMD_GROUP="curl -v -f -X POST
	-H \"Authorization: Bearer ${GL_TOKEN}\"
	-H \"Content-Type: application/json\"
	-d \"{
  \\\"name\\\": \\\"${GROUP_NAME}\\\",
  \\\"path\\\": \\\"${GROUP_PATH}\\\",
  \\\"visibility\\\": \\\"${VISIBILITY}\\\"
}\"
	 \"http://${GITL_HOST}/api/v4/groups\""

GL_BODY=$(loop_curl_until_success "${CMD_GROUP}")

call_show_finish_banner
