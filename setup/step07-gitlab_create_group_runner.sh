#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. ${CUR_DIR}/functions.sh
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

GITLAB_NM="gitlab"
GITLAB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ${GITLAB_NM} | awk '{print $NF}')
DTRACK_NM="dep-track-apiserver"
DTRACK_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ${DTRACK_NM} | awk '{print $NF}')
ARTFCT_NM="artifactory"
ARTFCT_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ${ARTFCT_NM} | awk '{print $NF}')
ANSIBL_NM="ansible"
ANSIBL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ${ANSIBL_NM} | awk '{print $NF}')
WEBAPI_NM=" webapp-webapi"
WEBAPI_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ${WEBAPI_NM} | awk '{print $NF}')
WEBUI_NM=" webapp-webui"
WEBUI_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' ${WEBUI_NM} | awk '{print $NF}')

echo ">>> ${GITLAB_NM} ip = [${GITLAB_IP}]"
echo ">>> ${DTRACK_NM} ip = [${DTRACK_IP}]"
echo ">>> ${ARTFCT_NM} ip = [${ARTFCT_IP}]"
echo ">>> ${ANSIBL_NM} ip = [${ANSIBL_IP}]"
echo ">>> ${WEBAPI_NM} ip = [${WEBAPI_IP}]"
echo ">>> ${WEBUI_NM} ip = [${WEBUI_IP}]"

docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab:13000" \
  --clone-url "http://gitlab:13000" \
  --token "${RUNNER_TOKEN}" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "docker-runner-alpine" \
  --docker-network-mode "host" \
  --docker-extra-hosts "${GITLAB_NM}:${GITLAB_IP}" \
  --docker-extra-hosts "${DTRACK_NM}:${DTRACK_IP}" \
  --docker-extra-hosts "${ARTFCT_NM}:${ARTFCT_IP}" \
  --docker-extra-hosts "${ANSIBL_NM}:${ANSIBL_IP}" \
  --docker-extra-hosts "${WEBAPI_NM}:${WEBAPI_IP}" \
  --docker-extra-hosts "${WEBUI_NM}:${WEBUI_IP}"

echo ">>> $ docker exec gitlab-runner cat /etc/gitlab-runner/config.toml"
docker exec gitlab-runner cat /etc/gitlab-runner/config.toml


echo "\n### START: restart gitlab-runner to apply the changed configuration"
docker restart gitlab-runner

call_show_finish_banner
