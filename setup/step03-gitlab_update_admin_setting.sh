#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab"

GL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab"

GL_TOKEN=$(get_gitlab_access_token $GL_USER $GL_PASS $GL_HOST)

echo "\n### START: update values of the admin settings in GitLab"

CMD_SETUP="curl -v -f -X PUT
	-H \"Authorization: Bearer $GL_TOKEN\"
	\"http://$GL_HOST/api/v4/application/settings?auto_devops_enabled=false&allow_local_requests_from_hooks_and_services=true&allow_local_requests_from_hooks_and_services=true&import_sources=gitlab_project\""

GL_BODY=$(loop_curl_until_success "$CMD_SETUP")

call_show_finish_banner
