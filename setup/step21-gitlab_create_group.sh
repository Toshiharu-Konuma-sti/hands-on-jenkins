#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/functions.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab ############################"

GL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab ############################"

GL_TOKEN=$(get_gitlab_access_token "${GITL_USER}" "${GL_PASS}" "${GITL_HOST}")

echo "\n### START: create a group ############################################"

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



echo "\n### START: get a group id ############################################"

CMD_GRP_ID="curl -v \
	-H \"Authorization: Bearer ${GL_TOKEN}\"
	\"http://${GITL_HOST}/api/v4/groups/${GROUP_PATH}\""

GL_BODY=$(loop_curl_until_success "${CMD_GRP_ID}")

GROUP_ID=$(echo "${GL_BODY}" | grep -o '"id":[0-9]*,' | head -n1 | sed 's/"id"://;s/,//')
echo ">>> group id = [${GROUP_ID}]"


echo "\n### START: create a group runner #####################################"

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


echo "\n### START: set up the configration for gitlab-runner #################"

GITLAB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' gitlab | awk '{print $NF}')
ARTIFACTORY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' artifactory | awk '{print $NF}')
ANSIBLE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ansible | awk '{print $NF}')
echo ">>> gitlab ip = [${GITLAB_IP}]"
echo ">>> artifactory ip = [${ARTIFACTORY_IP}]"
echo ">>> ansible ip = [${ANSIBLE_IP}]"

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab:13000" \
  --clone-url "http://gitlab:13000" \
  --token "${RUNNER_TOKEN}" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "docker-runner-alpine" \
  --docker-network-mode "host" \
  --docker-extra-hosts "gitlab:${GITLAB_IP}" \
  --docker-extra-hosts "artifactory:${ARTIFACTORY_IP}" \
  --docker-extra-hosts "ansible:${ANSIBLE_IP}"

echo ">>> $ docker exec gitlab-runner cat /etc/gitlab-runner/config.toml"
docker exec gitlab-runner cat /etc/gitlab-runner/config.toml


echo "\n### START: restart gitlab-runner to apply the changed configuration"
docker restart gitlab-runner


for MY_PROJ in ${WEBAPP_PROJECTS}; do

	echo "\n### START: get a project id (repository id) ##########################"

	PROJECT_FULL_PATH="${GITL_USER}/${MY_PROJ}"
	ENCODED_PATH=$(echo "${PROJECT_FULL_PATH}" | sed 's/\//%2F/g')

	PROJECT_INFO=$(curl -v \
		-H "Authorization: Bearer ${GL_TOKEN}" \
		"http://${GITL_HOST}/api/v4/projects/${ENCODED_PATH}")

	PROJECT_ID=$(echo "$PROJECT_INFO" | grep -o '"id":[0-9]*,' | head -n 1 | sed 's/"id"://;s/,//')
	echo ">>> project name & id = [${MY_PROJ}][${PROJECT_ID}]"


	echo "\n### START: transfer project(repository) from user to group ###########"

	CMD_TRANSFER="curl -v -f -X PUT
		-H \"Authorization: Bearer ${GL_TOKEN}\"
		\"http://${GITL_HOST}/api/v4/projects/${PROJECT_ID}/transfer?namespace=${GROUP_ID}\""

	GL_BODY=$(loop_curl_until_success "${CMD_TRANSFER}")

done

call_show_finish_banner
