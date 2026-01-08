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

GROUP_ID=$(echo ${GL_BODY} | grep -o '"id":[0-9]*,' | head -n1 | sed 's/"id"://;s/,//')

echo ">>> group name = [${GROUP_NAME}]"
echo ">>> group path = [${GROUP_PATH}]"
echo ">>> group id = [${GROUP_ID}]"

echo "\n### START: create a group runner"

CMD_RUNNER="curl -v -f -X POST
	-H \"Authorization: Bearer ${GL_TOKEN}\"
	-H \"Content-Type: application/json\"
	-d \"{
  \\\"runner_type\\\": \\\"group_type\\\",
  \\\"group_id\\\": ${GROUP_ID},
  \\\"description\\\": \\\"Group-Runner-API\\\",
  \\\"tag_list\\\": [],
  \\\"run_untagged\\\": true,
  \\\"locked\\\": false,
  \\\"access_level\\\": \\\"not_protected\\\"
}\"
	 \"http://${GITL_HOST}/api/v4/user/runners\""

GL_BODY=$(loop_curl_until_success "${CMD_RUNNER}")

RUNNER_TOKEN=$(echo "${GL_BODY}" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

echo ">>> runner token = [${RUNNER_TOKEN}]"

echo "\n### START: set up the configration for gitlab-runner"

GITLAB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' gitlab | awk '{print $NF}')
echo ">>> gitlab ip = [${GITLAB_IP}]"

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab:13000" \
  --clone-url "http://gitlab:13000" \
  --token "${RUNNER_TOKEN}" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "docker-runner-alpine" \
  --docker-network-mode "host" \
  --docker-extra-hosts "gitlab:${GITLAB_IP}"

echo ">>> $ docker exec gitlab-runner cat /etc/gitlab-runner/config.toml"
docker exec gitlab-runner cat /etc/gitlab-runner/config.toml

echo "\n### START: restart gitlab-runner to apply the changed configuration"
docker restart gitlab-runner

call_show_finish_banner
