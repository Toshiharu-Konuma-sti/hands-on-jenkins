#!/bin/sh

clear
S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/common.sh

start_banner

check_required_commands "java jq"
#	$CUR_DIR/step01-check_required_command.sh
$CUR_DIR/step02-jenkins_create_job.sh
$CUR_DIR/step03-gitlab_update_admin_setting.sh
$CUR_DIR/step04-gitlab_import_repository.sh
$CUR_DIR/step05-gitlab_setting_repository_webhook.sh
$CUR_DIR/step06-gitlab_setting_repository_variable.sh
$CUR_DIR/step07-gitlab_create_group.sh
$CUR_DIR/step08-gitlab_create_group_runner.sh

finish_banner $S_TIME
