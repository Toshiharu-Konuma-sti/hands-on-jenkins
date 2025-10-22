
# {{{ start_banner()
start_banner()
{
	echo "############################################################"
	echo "# START SCRIPT"
	echo "############################################################"
}
# }}}

# {{{ finish_banner()
# $1: time to start this script
finish_banner()
{
	S_TIME=$1
	E_TIME=$(date +%s)
	DURATION=$((E_TIME - S_TIME))
	echo "############################################################"
	echo "# FINISH SCRIPT ($DURATION seconds)"
	echo "############################################################"
}
# }}}

# {{{ call_own_fname()
call_own_fname()
{
	OFNM=$(basename $0)
	echo "$OFNM"
}
# }}}

# {{{ call_show_start_banner()
# $0: the name of the script being executed 
call_show_start_banner()
{
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n> START: Script = [$(call_own_fname)]\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}
# }}}

# {{{ call_show_finish_banner()
# $0: the name of the script being executed 
call_show_finish_banner()
{
	echo "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n< FINISH: Script = [$(call_own_fname)]\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
}
# }}}

# {{{ loop_curl_until_success()
# $1: the command to call with cURL
loop_curl_until_success()
{
	CMD_CURL=$1
	echo "$CMD_CURL" >&2
	BODY_CURL=""
	WAIT_SEC=5
	while true; do
		BODY_CURL=$(eval $CMD_CURL)
		if [ $? -eq 0 ]; then
			echo "-> result: connection successful." >&2
			break
		else
			echo "-> result: connection failed. will try again in $WAIT_SEC seconds." >&2
			sleep $WAIT_SEC
		fi
	done
	echo "$BODY_CURL" >&2
	echo "$BODY_CURL"
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

# {{{ prepare_download_dir()
# $1: the current directory
prepare_download_dir()
{
	CUR_DIR=$1
	DOWN_DIR=$CUR_DIR/../download
	mkdir -p $DOWN_DIR
	echo $DOWN_DIR
}
# }}}


# {{{ create_container()
# $1: the current directory
create_container()
{
	CUR_DIR=$1
	echo "\n### START: Create new containers ##########"
	docker volume create --name=artifactory_data
	docker volume create --name=postgres_data
	docker volume create --name=dtrack-data
	docker volume create --name=postgres-data
	docker-compose \
		-f $CUR_DIR/docker-compose.yml \
		-f $CUR_DIR/docker-compose-webapp.yml \
		-f $CUR_DIR/docker-compose-volumes.yaml \
		-f $CUR_DIR/docker-compose-dependencytrack.yml \
		up -d -V --remove-orphans
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
	docker-compose \
		-f $CUR_DIR/docker-compose.yml \
		-f $CUR_DIR/docker-compose-webapp.yml \
		-f $CUR_DIR/docker-compose-volumes.yaml \
		-f $CUR_DIR/docker-compose-dependencytrack.yml \
		down -v --remove-orphans
	docker volume rm artifactory_data
	docker volume rm postgres_data
	docker volume rm dtrack-data
	docker volume rm postgres-data
}
# }}}

# {{{ join_to_network()
join_to_network()
{
	echo "\n### START: Join to the network ##########"
	docker network connect hands-net artifactory
	docker network connect intra-net artifactory
	docker network connect intra-net postgresql
	docker network connect hands-net dep-track-apiserver
	docker network connect hands-net dep-track-frontend
	docker network connect intra-net dep-track-apiserver
	docker network connect intra-net dep-track-frontend
	docker network connect intra-net dep-track-postgres
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
		-f $CUR_DIR/docker-compose-volumes.yaml \
		up -d -V --build $CONTAINER_NM
}
# }}}

# {{{ clear_ssh_known_hosts()
# If a container is recreated (rebuild), it can not connect by SSH to a
# recreated container because the SSH public key will change, so clear the SSH
# public key registered in known_hosts.
# The connecting by SSH is mainly used on Ansible.
clear_ssh_known_hosts()
{
	echo "\n### START: Clear the know_hosts file for ssh ##########"
	docker exec ansible sh -c '[ -f ~/.ssh/known_hosts ] && > ~/.ssh/known_hosts'
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

# {{{ prepare_deptrack_server_name()
# $1: the current directory
# $2: the docker compose file name for dependency-track
# $3: api container name before change
# $4: api container name after change
# $5: frontend container name before change
# $6: frontend container name after change
# $7: postgresql container name before change
# $8: postgersql container name after change
prepare_deptrack_server_name()
{
	CUR_DIR=$1
	YAML_FIL=$2
	APIS_BEF=$3
	APIS_AFT=$4
	FRNT_BEF=$5
	FRNT_AFT=$6
	PSQL_BEF=$7
	PSQL_AFT=$8
	echo "### START: Replace container names in Dependency-Track's docker-compose YAML"

	# api server and frontend
	sed -i.bak \
		-e "s/^\([[:space:]]*\)${APIS_BEF}:/\1${APIS_AFT}:/" \
		-e "s/^\([[:space:]]*\)${FRNT_BEF}:/\1${FRNT_AFT}:/" "${CUR_DIR}/${YAML_FIL}"
	# postgresql
	sed -i.bak \
		-e "s/^\([[:space:]]*\)${PSQL_BEF}:/\1${PSQL_AFT}:/" \
		-e "s|//${PSQL_BEF}:|//${PSQL_AFT}:|" "${CUR_DIR}/${YAML_FIL}"
	# remove a back up file
	rm -f "${CUR_DIR}/${YAML_FIL}.bak"
}
# }}}

# {{{ prepare_deptrack_port_number()
# $1: the current directory
# $2: the docker compose file name for dependency-track
# $3: api port number before change
# $4: api port number after change
# $5: frontend port number before change
# $6: frontend port number after change
prepare_deptrack_port_number()
{
	CUR_DIR=$1
	YAML_FIL=$2
	APIS_BEF=$3
	APIS_AFT=$4
	FRNT_BEF=$5
	FRNT_AFT=$6
	echo "### START: Replace the port number exposed to the hosts in Dependency-Track's docker-compose YAML"

	sed -i.bak \
		-e "s/${APIS_BEF}/${APIS_AFT}/g" \
		-e "s/${FRNT_BEF}:/${FRNT_AFT}:/g" "${CUR_DIR}/${YAML_FIL}"
	rm -f "${CUR_DIR}/${YAML_FIL}.bak"
}
# }}}

# {{{ insert_deptrack_container_name()
# $1: the current directory
# $2: the docker compose file name for dependency-track
# $3: api container name after change
# $4: frontend container name after change
# $5: postgersql container name after change
insert_deptrack_container_name()
{
	CUR_DIR=$1
	YAML_FIL=$2
	APIS_AFT=$3
	FRNT_AFT=$4
	PSQL_AFT=$5
	echo "### START: Insert the container name in Dependency-Track's docker-compose YAML"

	sed -i.bak "s/^  ${APIS_AFT}:/  ${APIS_AFT}:\n    container_name: ${APIS_AFT}/" "${CUR_DIR}/${YAML_FIL}"
	sed -i.bak "s/^  ${FRNT_AFT}:/  ${FRNT_AFT}:\n    container_name: ${FRNT_AFT}/" "${CUR_DIR}/${YAML_FIL}"
	sed -i.bak "s/^  ${PSQL_AFT}:/  ${PSQL_AFT}:\n    container_name: ${PSQL_AFT}/" "${CUR_DIR}/${YAML_FIL}"
	rm -f "${CUR_DIR}/${YAML_FIL}.bak"
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

# {{{ prepare_jfrog_oss_files()
# $1: the current directory
# $2: the download directory
# $3: the artifactory directory pattern
prepare_jfrog_oss_files()
{
	CUR_DIR=$1
	DWN_DIR=$2
	DIR_PTN=$3
	echo "\n### START: Prepare JFrog OSS files ##########"
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
	DWN_DIR=$1
	PKG_URL=$2
	echo "\n### START: Get webapp package from the repository in GitHub ##########"
	PKG_FILE=$(basename $PKG_URL)
	PKG_PATH=$DWN_DIR/$PKG_FILE
	curl -LO --output-dir $DWN_DIR $PKG_URL
	unzip -o $PKG_PATH -d $DWN_DIR
}
# }}}

# {{{ prepare_webapp_mysql_files()
# $1: the current directory
# $2: the download directory
# $3: the webapp package url
prepare_webapp_mysql_files()
{
	CUR_DIR=$1
	DWN_DIR=$2
	PKG_URL="$3"

	echo "\n### START: Prepare webapp MySQL files ##########"
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
	GIT_REPO=$(echo $PKG_URL | cut -d '/' -f 5)
	GIT_BRANCH=$(basename $PKG_URL | sed "s/\.[^.]*$//")

	for MY_PROJ in $WEBAPP_PROJECTS; do
		PROJ_DIR=$(echo $MY_PROJ | sed -e "s/.*-//g")

		mv -f $DWN_DIR/$GIT_REPO-$GIT_BRANCH/$PROJ_DIR/* $CUR_DIR/$MY_PROJ/
		mv -f $DWN_DIR/$GIT_REPO-$GIT_BRANCH/$PROJ_DIR/.git* $CUR_DIR/$MY_PROJ/
	done
}
# }}}

# {{{ clean_webapp_package()
# $1: the download directory
# $2: the webapp package url
clean_webapp_package()
{
	DWN_DIR=$1
	PKG_URL=$2
	echo "\n### START: Clean webapp package ##########"
	PKG_FILE=$(basename $PKG_URL)
	PKG_PATH=$DWN_DIR/$PKG_FILE
	GIT_REPO=$(echo $PKG_URL | cut -d '/' -f 5)
	GIT_BRANCH=$(basename $PKG_URL | sed 's/\.[^.]*$//')

	rm -f $PKG_PATH
	rm -rf $DWN_DIR/$GIT_REPO-$GIT_BRANCH/
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
	for MY_PROJ in $WEBAPP_PROJECTS; do
		PROJ_DIR=$(echo $MY_PROJ | sed -e "s/.*-//g")

		rm -rf $CUR_DIR/$MY_PROJ
		git clone http://$GL_HOST/$GL_USER/$MY_PROJ.git
		git -C $CUR_DIR/$MY_PROJ/ checkout -b feature/sample
	done
}
# }}}


# {{{ show_list_container()
show_list_container()
{
	echo "\n### START: Show a list of container ##########"
	docker ps -a
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
 *   - Dependency-Track:    http://localhost:8980
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
	echo "  1. Run the script in the console. It will clone GitLab repository and add the webapp codes: \e[4mtry-my-hand/PREPARE_CODING.sh\e[m"
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
