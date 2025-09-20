
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
  \\\"username\\\": \\\"$GL_USER\\\",
  \\\"password\\\": \\\"$GL_PASS\\\"
}\"
		\"http://$GL_HOST/oauth/token\""

	GL_BODY=$(loop_curl_until_success "$CMD_TOKEN")

	GL_TOKEN=$(echo $GL_BODY | \
		jq '.access_token' | \
		sed -z 's/\n//' | sed -z 's/\r//' | \
		sed -e 's/"//g' | \
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
	docker-compose \
		-f $CUR_DIR/docker-compose.yml \
		-f $CUR_DIR/docker-compose-webapp.yml \
		-f $CUR_DIR/docker-compose-volumes.yaml \
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
		down -v --remove-orphans
	docker volume rm artifactory_data
	docker volume rm postgres_data
}
# }}}

# {{{ join_to_network()
join_to_network()
{
	docker network connect hands-net artifactory
	docker network connect intra-net artifactory
	docker network connect intra-net postgresql
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
clear_ssh_known_hosts()
{
	echo "\n### START: Clear the know_hosts file for ssh ##########"
	docker exec ansible sh -c '[ -f ~/.ssh/known_hosts ] && > ~/.ssh/known_hosts'
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

	echo "# dummy" >> $CUR_DIR/.env
	echo "JF_SHARED_NODE_IP=$(hostname -i)" >> $CUR_DIR/.env
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
	echo "\n### START: Get webapp package ##########"
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
	GIT_REPO=$(echo $PKG_URL | cut -d '/' -f 5)
	GIT_BRANCH=$(basename $PKG_URL | sed 's/\.[^.]*$//')

	cp -rf $DWN_DIR/$GIT_REPO-$GIT_BRANCH/mysql/ $CUR_DIR

	echo "" >> $CUR_DIR/.env
	echo "DB_ROOT_PASS=password" >> $CUR_DIR/.env
	echo "DB_NAME=mytest" >> $CUR_DIR/.env
	echo "DB_USER=myuser" >> $CUR_DIR/.env
	echo "DB_PASS=mypass" >> $CUR_DIR/.env
}
# }}}

# {{{ clone_gitlab_repo_with_branch()
# $1: the current directory
# $2: the download directory
# $3: the webapp package url
# $4: the list of the names of webapp repository
clone_gitlab_repo_with_branch()
{
	CUR_DIR="$1"
	DWN_DIR="$2"
	PKG_URL="$3"
	WEBAPP_PROJECTS="$4"
	echo "\n### START: Prepare GitLab repository and create a brunch ##########"
	GIT_REPO=$(echo $PKG_URL | cut -d '/' -f 5)
	GIT_BRANCH=$(basename $PKG_URL | sed "s/\.[^.]*$//")

	for MY_PROJ in $WEBAPP_PROJECTS; do
		PROJ_DIR=$(echo $MY_PROJ | sed -e "s/.*-//g")

		rm -rf $CUR_DIR/$MY_PROJ
		git clone http://$GL_HOST/$GL_USER/$MY_PROJ.git
		git -C $CUR_DIR/$MY_PROJ/ checkout -b feature/sample

		rm -rf $CUR_DIR/$MY_PROJ/*/

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
 * - Access to Web ui tools with the URL below.
 *   - Jenkins:     http://localhost:8080/
 *   - Artifactory: http://localhost:8082/
 *   - GitLab:      http://localhost:13000/
 * - Access to the deployed webapp with the URL below.
 *   - webapp:      http://localhost:8181/
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
	echo "  1. Access Jenkins and apply JCasC: \e[4m/var/jenkins_home/my-config/jcasc/jenkins.yaml\e[m"
	echo "  2. Access Artifactory and create repositories: \e[4mhands-on-webapp-webapi\e[m and \e[4mhands-on-webapp-webui\e[m"
	echo "  3. Run the setup script: \e[4msetup/SETUP_HANDS-ON.sh\e[m"
	echo "  4. Run the coding preparation script: \e[4mtry-my-hand/PREPARE_CODING.sh\e[m"
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
