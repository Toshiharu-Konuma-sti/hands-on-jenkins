#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab"

GITL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab"

GL_TOKEN=$(get_gitlab_access_token $GITL_USER $GITL_PASS $GITL_HOST)

echo "\n### START: import a repository's webhook to GitLab"

for MY_PROJ in $WEBAPP_PROJECTS; do
	CMD_HOOK="curl -v -f -X POST
		-H \"Authorization: Bearer $GL_TOKEN\"
		-H \"Content-Type: application/json\"
		-d \"{
  \\\"name\\\": \\\"jenkins-build-$MY_PROJ\\\",
  \\\"url\\\": \\\"http://$JENK_HOST_INT/project/build-$MY_PROJ\\\",
  \\\"merge_requests_events\\\": true,
  \\\"token\\\": \\\"$JENK_JOB_TOKEN\\\"
}\"
	 \"http://$GITL_HOST/api/v4/projects/$GITL_USER%2F$MY_PROJ/hooks\""

	GL_BODY=$(loop_curl_until_success "$CMD_HOOK")
done

call_show_finish_banner
