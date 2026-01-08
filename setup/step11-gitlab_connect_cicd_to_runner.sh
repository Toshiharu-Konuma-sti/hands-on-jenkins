#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/functions.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab"

GL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab"

GL_TOKEN=$(get_gitlab_access_token "${GITL_USER}" "${GL_PASS}" "${GITL_HOST}")


for MY_PROJ in ${WEBAPP_PROJECTS}; do

	echo "\n### START: get a project id (repository id)"

	PROJECT_FULL_PATH="${GITL_USER}/${MY_PROJ}"
	ENCODED_PATH=$(echo "${PROJECT_FULL_PATH}" | sed 's/\//%2F/g')

	PROJECT_INFO=$(curl -v \
		-H "Authorization: Bearer ${GL_TOKEN}" \
		"http://${GITL_HOST}/api/v4/projects/${ENCODED_PATH}")

	PROJECT_ID=$(echo "$PROJECT_INFO" | grep -o '"id":[0-9]*,' | head -n 1 | sed 's/"id"://;s/,//')
	echo ">>> project name & id = [${MY_PROJ}][${PROJECT_ID}]"


	echo "\n### START: get a runner auth token"

	RUNNER_INFO=$(curl -v -X POST \
		-H "Authorization: Bearer ${GL_TOKEN}" \
		-H "Content-Type: application/json" \
		-d "{
\"runner_type\": \"project_type\",
\"project_id\": ${PROJECT_ID},
\"description\": \"API-Created-Runner\",
\"tag_list\": [],
\"run_untagged\": true,
\"locked\": false,
\"access_level\": \"not_protected\"
}" \
		"http://${GITL_HOST}/api/v4/user/runners")

	RUNNER_TOKEN=$(echo ${RUNNER_INFO} | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
	echo ">>> runner auth token = [${RUNNER_TOKEN}]"


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

done

echo "\n### START: restart gitlab-runner to apply the changed configuration"
docker restart gitlab-runner

call_show_finish_banner

exit



echo "\n### START: import a repository's webhook to GitLab"

for MY_PROJ in ${WEBAPP_PROJECTS}; do
	CMD_HOOK="curl -v -f -X POST
		-H \"Authorization: Bearer ${GL_TOKEN}\"
		-H \"Content-Type: application/json\"
		-d \"{
  \\\"name\\\": \\\"jenkins-build-${MY_PROJ}\\\",
  \\\"url\\\": \\\"http://${JENK_HOST_INT}/project/build-${MY_PROJ}\\\",
  \\\"merge_requests_events\\\": true,
  \\\"token\\\": \\\"${JENK_JOB_TOKEN}\\\"
}\"
	 \"http://${GITL_HOST}/api/v4/projects/${GITL_USER}%2F${MY_PROJ}/hooks\""

	GL_BODY=$(loop_curl_until_success "${CMD_HOOK}")
done

call_show_finish_banner
