#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/common.sh
. ${CUR_DIR}/custom.sh
. ${CUR_DIR}/variables.sh

call_show_start_banner

echo "\n### START: get root's password for GitLab ############################"

GL_PASS=$(get_gitlab_root_password)

echo "\n### START: get an access token for GitLab ############################"

GL_TOKEN=$(get_gitlab_access_token "${GITL_USER}" "${GL_PASS}" "${GITL_HOST}")


echo "\n### START: get a group id ############################################"

CMD_GRP_ID="curl -v \
	-H \"Authorization: Bearer ${GL_TOKEN}\"
	\"http://${GITL_HOST}/api/v4/groups/${GITL_GRP_PATH}\""

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

echo ">>> Clear existing configuration in config.toml"
docker exec gitlab-runner touch /etc/gitlab-runner/config.toml
docker exec gitlab-runner sh -c '> /etc/gitlab-runner/config.toml'

echo ">>> Register github runner"
TARGET_CONTAINERS="gitlab dtrack-apiserver artifactory ansible webapp-webapi webapp-webui"
EXTRA_HOSTS_OPTS=""

for CONTAINER_NM in ${TARGET_CONTAINERS}; do
	if docker inspect ${CONTAINER_NM} > /dev/null 2>&1; then
		IS_RUNNING=$(docker inspect -f '{{.State.Running}}' ${CONTAINER_NM} 2>/dev/null)
		if [ "${IS_RUNNING}" = "true" ]; then
			CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ${CONTAINER_NM} 2>/dev/null | awk '{print $NF}')
			if [ -n "${CONTAINER_IP}" ]; then
				echo ">>> Found ${CONTAINER_NM} ip = [${CONTAINER_IP}] -> Adding to extra-hosts"
				EXTRA_HOSTS_OPTS="${EXTRA_HOSTS_OPTS} --docker-extra-hosts ${CONTAINER_NM}:${CONTAINER_IP}"
			else
				echo ">>> Skipping ${CONTAINER_NM}: IP address is empty."
			fi
		else
			echo ">>> Skipping ${CONTAINER_NM}: Container is NOT running (State: ${IS_RUNNING})"
		fi
	else
		echo ">>> Skipping ${CONTAINER_NM}: Container does not exist"
	fi
done

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab:13000" \
  --clone-url "http://gitlab:13000" \
  --token "${RUNNER_TOKEN}" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "docker-runner-alpine" \
  --docker-network-mode "host" \
  ${EXTRA_HOSTS_OPTS}

echo ">>> $ docker exec gitlab-runner cat /etc/gitlab-runner/config.toml"
docker exec gitlab-runner cat /etc/gitlab-runner/config.toml


echo "\n### START: restart gitlab-runner to apply the changed configuration"
docker restart gitlab-runner

call_show_finish_banner
