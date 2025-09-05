#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab"

GL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab"

GL_TOKEN=$(get_gitlab_access_token $GL_USER $GL_PASS $GL_HOST)

echo "\n### START: import repositories to GitLab"

for MY_PROJ in $WEBAPP_PROJECTS; do
	CMD_IMPORT="curl -v -f -X POST
		-H \"Authorization: Bearer $GL_TOKEN\"
		-F \"path=$MY_PROJ\"
		-F \"file=@./gitlab/project/$MY_PROJ.tar.gz\"
		\"http://$GL_HOST/api/v4/projects/import\""

	GL_BODY=$(loop_curl_until_success "$CMD_IMPORT")
done

call_show_finish_banner
