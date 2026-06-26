
# {{{ create_container()
# $1: the current directory
create_container()
{
	CUR_DIR=$1
	echo "\n### START: Create new containers ##########"
#	docker volume create --name=artifactory_data
#	docker volume create --name=postgres_data
#	docker volume create --name=dtrack-data
#	docker volume create --name=postgres-data
#	docker-compose \
#		-f $CUR_DIR/docker-compose.yml \
#		-f $CUR_DIR/docker-compose-webapp.yml \
#		-f $CUR_DIR/docker-compose-volumes.yaml \
#		-f $CUR_DIR/docker-compose-dependencytrack.yml \
#		up -d -V --remove-orphans

	docker compose \
		-f $CUR_DIR/docker-compose.yml \
		-f $CUR_DIR/docker-compose-webapp.yml \
		-f $CUR_DIR/docker-compose.common.network.yml \
		-p devops \
		up -d -V --remove-orphans
	docker compose \
		-f $CUR_DIR/docker-compose-dtrack.yml \
		-f $CUR_DIR/docker-compose-dtrack-override.yml \
		-p dtrack \
		up -d -V
	docker compose \
		-f $CUR_DIR/docker-compose-volumes.yaml \
		-f $CUR_DIR/docker-compose-jfrog-override.yml \
		-p jfrog \
		up -d -V
}
# }}}

# {{{ create_container_exporter()
# $1: the current directory
create_container_exporter()
{
	CUR_DIR=$1
	echo "\n### START: Create the node exporter containers ##########"
	docker-compose \
		-f $CUR_DIR/docker-compose-webapp.yml \
		-f $CUR_DIR/docker-compose-webapp-exporter.yml \
		up -d
}
# }}}

# {{{ destory_container()
# $1: the current directory
destory_container()
{
	CUR_DIR=$1
	echo "\n### START: Destory existing containers ##########"
#	docker-compose \
#		-f $CUR_DIR/docker-compose.yml \
#		-f $CUR_DIR/docker-compose-webapp.yml \
#		-f $CUR_DIR/docker-compose-volumes.yaml \
#		-f $CUR_DIR/docker-compose-dependencytrack.yml \
#		down -v --remove-orphans

	docker compose \
		-f $CUR_DIR/docker-compose-volumes.yaml \
		-f $CUR_DIR/docker-compose-jfrog-override.yml \
		-p jfrog \
		down -v
	docker compose \
		-f $CUR_DIR/docker-compose-dtrack.yml \
		-f $CUR_DIR/docker-compose-dtrack-override.yml \
		-p dtrack \
		down -v
	docker compose \
		-f $CUR_DIR/docker-compose.yml \
		-f $CUR_DIR/docker-compose-webapp.yml \
		-f $CUR_DIR/docker-compose.common.network.yml \
		-p devops \
		down -v --remove-orphans

#	docker volume rm artifactory_data
#	docker volume rm postgres_data
#	docker volume rm dtrack-data
#	docker volume rm postgres-data
}
# }}}

# {{{ rebuild_container()
# $1: the current directory
# $2: the name of container to rebuild
rebuild_container()
{
	CUR_DIR=$1
	CONTAINER_NM=$2
	echo "\n### START: Rebuild a container ##########"
	docker stop $CONTAINER_NM
	IMAGE_NM=$(docker inspect --format='{{.Config.Image}}' $CONTAINER_NM)
	docker rm $CONTAINER_NM
	docker rmi $IMAGE_NM
	docker-compose \
		-f $CUR_DIR/docker-compose.yml \
		-f $CUR_DIR/docker-compose-webapp.yml \
		-f $CUR_DIR/docker-compose.common.network.yml \
		-p devops \
		up -d -V --build $CONTAINER_NM
}
# }}}

# {{{ clear_ssh_known_hosts_on_ssh_client()
# If a container is recreated (rebuild), it can not connect by SSH to a
# recreated container because the SSH public key will change, so clear the SSH
# public key registered in known_hosts.
# The connecting by SSH is mainly used on Ansible.
clear_ssh_known_hosts_on_ssh_client()
{
	echo "\n### START: Clear the know_hosts file for ssh ##########"
	docker exec ansible sh -c '[ -f ~/.ssh/known_hosts ] && > ~/.ssh/known_hosts'
}
# }}}


# {{{ get_jenkins_cli()
get_jenkins_cli()
{
	echo "\n### START: get a jenkins cli"
	JK_CLI_PATH=$1
	JK_HOST=$2
	JK_CLI_JAR=$3
	wget -O ${JK_CLI_PATH} http://${JK_HOST}/jnlpJars/${JK_CLI_JAR}
}
# }}}

# {{{ remove_jenkins_cli()
remove_jenkins_cli()
{
	echo "\n### START: remove a jenkins cli"
	JK_CLI_PATH=$1
	rm -f ${JK_CLI_PATH}
}
# }}}

# {{{ listing_jenkins_job_config()
listing_jenkins_job_config()
{
	CUR_DIR=$1
	FND_DIR="${CUR_DIR}/jenkins/jobs/"
	PATTERN="config-*.xml"
	FILE_LIST=$(find "${FND_DIR}" -type f -name "${PATTERN}")
	echo "${FILE_LIST}"
}
# }}}

# {{{ import_jenkins_job()
import_jenkins_job()
{
	JK_CLI_PATH=$1
	JK_HOST=$2
	JK_USER=$3
	JK_PASS=$4
	JK_JOB_TOKEN=$5
	F_LIST=$6

	echo "\n### START: create jobs to Jenkins"
	for F_PATH in ${F_LIST}
	do
		JOB_NAME=$(basename "${F_PATH}" | sed 's/^config-//; s/\.xml$//')
		echo ">>> register the '${JOB_NAME}' job"
		case "${JOB_NAME}" in
			build-*)
				sed "s|<secretToken>.*</secretToken>|<secretToken>${JK_JOB_TOKEN}</secretToken>|" ${F_PATH} | \
					java -jar ${JK_CLI_PATH} -s http://${JK_HOST}/ -auth ${JK_USER}:${JK_PASS} create-job ${JOB_NAME}
				;;
			*)
				java -jar ${JK_CLI_PATH} -s http://${JK_HOST}/ -auth ${JK_USER}:${JK_PASS} create-job ${JOB_NAME} < ${F_PATH}
				;;
		esac
	done
}
# }}}


# {{{ get_gitlab_root_password()
get_gitlab_root_password()
{
	GL_PASS=$(docker container exec gitlab cat /etc/gitlab/initial_root_password | \
		grep "^Password" | \
		sed -e "s/^Password: //g" | \
		tee /dev/tty)
	echo "$GL_PASS"
}
# }}}

# {{{ get_gitlab_access_token()
# $1: GitLab user name
# $2: GitLab password
# $3: GitLab host name
get_gitlab_access_token()
{
	GL_USER=$1
	GL_PASS=$2
	GL_HOST=$3

	CMD_TOKEN="curl -v -f -X POST
		-H \"Content-Type: application/json\"
		-d \"{
  \\\"grant_type\\\": \\\"password\\\",
  \\\"username\\\": \\\"${GL_USER}\\\",
  \\\"password\\\": \\\"${GL_PASS}\\\"
}\"
		\"http://${GL_HOST}/oauth/token\""

	GL_BODY=$(loop_curl_until_success "${CMD_TOKEN}")

	GL_TOKEN=$(echo "${GL_BODY}" | \
		jq -r '.access_token' | \
		tr -d '\n\r' | \
		tee /dev/tty)

	echo "$GL_TOKEN"
}
# }}}


# {{{ get_dependencytrack_yaml()
# $1: the current directory
# $2: url
# $3: file name
get_dependencytrack_yaml()
{
	CUR_DIR=$1
	YAML_URL=$2
	YAML_FIL=$3
	echo "\n### START: Get docker-compose YAML for Dependency-Track ##########"
	curl -L -o $CUR_DIR/$YAML_FIL $YAML_URL
}
# }}}

# {{{ replace_dtrack_port_number()
# $1: the current directory
# $2: the docker compose file name for dependency-track
# $3: api port number before change
# $4: api port number after change
# $5: frontend port number before change
# $6: frontend port number after change
replace_dtrack_port_number()
{
	CUR_DIR=$1
	YAML_FIL=$2
	APIS_BEF=$3
	APIS_AFT=$4
	FRNT_BEF=$5
	FRNT_AFT=$6
	echo "### START: Replace the port number exposed to the hosts in Dependency-Track's docker-compose YAML"

	sed -i.bak \
		-e "s/:${APIS_BEF}:8080/:${APIS_AFT}:8080/g" \
		-e "s/\"${APIS_BEF}:8080/\"${APIS_AFT}:8080/g" \
		-e "s/localhost:${APIS_BEF}/localhost:${APIS_AFT}/g" \
		-e "s/:${FRNT_BEF}:8080/:${FRNT_AFT}:8080/g" \
		-e "s/\"${FRNT_BEF}:8080/\"${FRNT_AFT}:8080/g" \
		-e "s/localhost:${FRNT_BEF}/localhost:${FRNT_AFT}/g" \
		"${CUR_DIR}/${YAML_FIL}"

	rm -f "${CUR_DIR}/${YAML_FIL}.bak"
}
# }}}

# {{{ get_dtrack_access_token()
# $1: Dependency-Track user name
# $2: Dependency-Track password
# $2: Dependency-Track API host name
get_dtrack_access_token()
{
	DT_USER=$1
	DT_PASS=$2
	DT_HOST=$3

	CMD_TOKEN="curl -v -X POST
		-H \"Content-Type: application/x-www-form-urlencoded\"
		-d \"username=${DT_USER}\"
		-d \"password=${DT_PASS}\"
		\"http://${DT_HOST}/api/v1/user/login\""
	TOKEN=$(loop_curl_until_success "${CMD_TOKEN}")

	echo "${TOKEN}"
}
# }}}


# {{{ get_jfrog_oss_package()
# $1: the download directory
# $2: the artifactory package url
# $3: the artifactory package pattern
get_jfrog_oss_package()
{
	DWN_DIR=$1
	PKG_URL=$2
	PKG_PTN=$3
	PKG_PATH=$DWN_DIR/$PKG_PTN
	echo "\n### START: Get JFrog OSS package ##########"
	curl -LO --output-dir $DWN_DIR $PKG_URL
	tar -zxvf $PKG_PATH -C $DWN_DIR
}
# }}}

# {{{ move_jfrog_oss_files()
# $1: the current directory
# $2: the download directory
# $3: the artifactory directory pattern
move_jfrog_oss_files()
{
	CUR_DIR=$1
	DWN_DIR=$2
	DIR_PTN=$3
	echo "\n### START: Move JFrog OSS files ##########"
	cp -f $DWN_DIR/$DIR_PTN/templates/docker-compose-volumes.yaml $CUR_DIR
	cp -f $DWN_DIR/$DIR_PTN/.env $CUR_DIR

	OS_TYPE=$(uname -s)
	IP_ADDRESS=""
	if [ "${OS_TYPE}" = "Darwin" ]; then
		IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
	else
		IP_ADDRESS=$(ip route get 1.1.1.1 | awk '{printf "%s", $7}')
	fi

	echo "" >> $CUR_DIR/.env
	echo "# added the environment variables below" >> $CUR_DIR/.env
	echo "JF_SHARED_NODE_IP=${IP_ADDRESS}" >> $CUR_DIR/.env
	echo "JF_SHARED_NODE_ID=$(hostname -s)" >> $CUR_DIR/.env
	echo "JF_SHARED_NODE_NAME=$(hostname -s)" >> $CUR_DIR/.env
}
# }}}

# {{{ clean_jfrog_oss_package()
# $1: the download directory
# $2: the artifactory package pattern
# $3: the artifactory directory pattern
clean_jfrog_oss_package()
{
	DWN_DIR=$1
	PKG_PTN=$2
	DIR_PTN=$3
	echo "\n### START: Clean JFrog OSS package ##########"
	rm -f $DWN_DIR/$PKG_PTN
	rm -rf $DWN_DIR/$DIR_PTN
}
# }}}


# {{{ get_webapp_package()
# $1: the download directory
# $2: the webapp package url
get_webapp_package()
{
	DWN_DIR="$1"
	PKG_URL="$2"
	echo "\n### START: Get webapp package from the repository in GitHub ##########"
	PKG_FILE=$(basename "${PKG_URL}")
	PKG_PATH="${DWN_DIR}/${PKG_FILE}"
	curl -LO --output-dir "${DWN_DIR}" "${PKG_URL}"
	unzip -o "${PKG_PATH}" -d "${DWN_DIR}"
}
# }}}

# {{{ move_webapp_mysql_files()
# $1: the current directory
# $2: the download directory
# $3: the webapp package url
move_webapp_mysql_files()
{
	CUR_DIR=$1
	DWN_DIR=$2
	PKG_URL="$3"

	echo "\n### START: Move webapp MySQL files ##########"
	GIT_REPO=$(echo ${PKG_URL} | cut -d '/' -f 5)
	GIT_BRANCH=$(basename ${PKG_URL} | sed 's/\.[^.]*$//')

	cp -rf "${DWN_DIR}/${GIT_REPO}-${GIT_BRANCH}/mysql" "${CUR_DIR}/"
	cp -f  "${DWN_DIR}/${GIT_REPO}-${GIT_BRANCH}/.env-webapp-mysql" "${CUR_DIR}/"
}
# }}}

# {{{ move_webapp_codes_to_repo()
# $1: the current directory
# $2: the download directory
# $3: the rolling dice webapp package url in github
# $4: the list of the names of webapp repository
move_webapp_codes_to_repo()
{
	CUR_DIR="$1"
	DWN_DIR="$2"
	PKG_URL="$3"
	WEBAPP_PROJECTS="$4"

	echo "\n### START: Move webapp codes to GitLab repository ##########"
	GIT_REPO=$(echo "${PKG_URL}" | cut -d '/' -f 5)
	GIT_BRANCH=$(basename "${PKG_URL}" | sed "s/\.[^.]*$//")

	for MY_PROJ in ${WEBAPP_PROJECTS}; do
		PROJ_DIR=$(echo "${MY_PROJ}" | sed -e "s/.*-//g")

		# mv -f "${DWN_DIR}/${GIT_REPO}-${GIT_BRANCH}/${PROJ_DIR}/"* "${CUR_DIR}/${MY_PROJ}/"
		# mv -f "${DWN_DIR}/${GIT_REPO}-${GIT_BRANCH}/${PROJ_DIR}/.git"* "${CUR_DIR}/${MY_PROJ}/"
		rsync -a --remove-source-files "${DWN_DIR}/${GIT_REPO}-${GIT_BRANCH}/${PROJ_DIR}/" "${CUR_DIR}/${MY_PROJ}/"
	done
}
# }}}

# {{{ clean_webapp_package()
# $1: the download directory
# $2: the webapp package url
clean_webapp_package()
{
	DWN_DIR="$1"
	PKG_URL="$2"
	echo "\n### START: Clean webapp package ##########"
	PKG_FILE=$(basename "${PKG_URL}")
	PKG_PATH="${DWN_DIR}/${PKG_FILE}"
	GIT_REPO=$(echo "${PKG_URL}" | cut -d '/' -f 5)
	GIT_BRANCH=$(basename "${PKG_URL}" | sed 's/\.[^.]*$//')

	rm -f "${PKG_PATH}"
	rm -rf "${DWN_DIR}/${GIT_REPO}-${GIT_BRANCH}/"
}
# }}}

# {{{ clone_gitlab_repo_with_branch()
# $1: the current directory
# $2: the download directory
# $3: the gitlab host name
# $4: the gitlab user name
# $5: the list of the names of webapp repository
clone_gitlab_repo_with_branch()
{
	CUR_DIR="$1"
	DWN_DIR="$2"
	GL_HOST="$3"
	GL_USER="$4"
	WEBAPP_PROJECTS="$5"

	echo "\n### START: Clone gitlab repository with branch ##########"
	for MY_PROJ in ${WEBAPP_PROJECTS}; do
		rm -rf "${CUR_DIR}/${MY_PROJ}"
		git clone "http://${GL_HOST}/${GL_USER}/${MY_PROJ}.git"
		git -C "${CUR_DIR}/${MY_PROJ}/" checkout -b feature/sample
	done
}
# }}}


# {{{ show_url()
show_url()
{
	cat << EOS

/************************************************************
 * Information:
 * - Navigate to Web ui tools with the URL below.
 *   - Jenkins:             http://localhost:8080
 *   - Dependency-Track:    http://localhost:8981
 *   - Artifactory:         http://localhost:8082
 *   - GitLab:              http://localhost:13000
 * - Navigate to the deployed webapp with the URL below.
 *   - webapp:              http://localhost:8181
 * - Navigate to the external web service with the URL below.
 *   - Sonatype OSS Index   https://ossindex.sonatype.org
 ***********************************************************/
EOS
}
# }}}

# {{{ show_command()
show_command()
{
	cat << EOS

### START: Show the commands to get a password ##########
Enter the command below to get a default password after each container started.
- for GitLab(root):  $ docker container exec gitlab cat /etc/gitlab/initial_root_password
- for Jenkins:       $ docker container exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

EOS
}
# }}}

# {{{ show_passwords()
show_password()
{
	PW_JK=$(docker container exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)
	PW_GL=$(docker container exec gitlab cat /etc/gitlab/initial_root_password | grep "^Password" | sed -e "s/^Password: //g")
	cat << EOS
- Password:
  - Jenkins Default: $PW_JK
  - GitLab root user: $PW_GL
EOS
}
# }}}

# {{{ show_information()
show_information()
{
	echo "- Setup Instructions:"
	echo "  1. Go to Jenkins and apply JCasC: \e[4m/var/jenkins_home/my-config/jcasc/jenkins.yaml\e[m"
	echo "  2. Go to Sonatype OSS Index and get it's API Token."
	echo "  3. Go to Dependency-Track and update Sonatype OSS Index registered email and API Token."
	echo "  4. Issue an API-Key in Dependency-Track."
	echo "  5. Go to Jenkins and update it with the API key issued by Dependency-Track."
	echo "  6. Go to Artifactory and a create local repositories: \e[4mhands-on-rollingdice-webapp-webapi\e[m and \e[4mhands-on-rollingdice-webapp-webui\e[m"
	echo "  7. Create a remote repository and a virtual repository that links local and remote: \e[4mmaven-central-remote\e[m and \e[4mgradle-virtual\e[m"
	echo "  8. Run the setup script in the console: \e[4msetup/SETUP_HANDS-ON.sh\e[m"
	echo "- CI/CD Instructions:"
	echo "  1. Run the script in the console. It will clone GitLab repository and add the webapp codes: \e[4mtry-my-hand/PREPARE_LOCAL_GIT_REPO_TO_PUSH.sh\e[m"
	echo "  2. Push a local repository including webapp codes to GitLab."
	echo "  3. Go to GitLab and merge the branch in the repository."
	echo "  4. Go to Jenkins and check that the job has started."
	echo "  5. Run the deployment job in Jenkins."
	echo ""
}
# // }}}

# {{{ show_usage()
show_usage()
{
	cat << EOS
Usage: $(basename $0) [options]

Start the containers needed for the hands-on. If there are any containers
already running, stop them and remove resources beforehand.

Options:
  up                    Start the containers.
  up-exporter           Start the node exporter containers.
  down                  Stop the containers and remove resources.
  rebuild {container}   Stop the specified container, removes its image, and
                        restarts it.
  list                  Show the list of containers.
  info                  Show the information such as URLs.

EOS
}
# }}}



