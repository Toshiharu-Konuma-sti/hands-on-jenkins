#!/bin/sh

clear
S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh

start_banner

$CUR_DIR/step01-install_command.sh
$CUR_DIR/step02-jenkins_create_job.sh
$CUR_DIR/step03-gitlab_update_admin_setting.sh
$CUR_DIR/step04-gitlab_import_repository.sh
$CUR_DIR/step05-gitlab_setting_repository_webhook.sh

finish_banner $S_TIME
