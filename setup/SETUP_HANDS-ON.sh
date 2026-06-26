#!/bin/sh

clear
S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/common.sh

start_banner

check_required_commands "java jq"
$CUR_DIR/step11-jenkins_create_job.sh
$CUR_DIR/step21-dtrack_change_admin_password.sh
$CUR_DIR/step22-dtrack_enable_osv.sh
$CUR_DIR/step23-dtrack_generate_apikey_and_update_jenkins_secret.sh
$CUR_DIR/step31-gitlab_update_admin_setting.sh
$CUR_DIR/step32-gitlab_import_repository.sh
$CUR_DIR/step33-gitlab_setting_repository_webhook.sh
$CUR_DIR/step34-gitlab_setting_repository_variable.sh
$CUR_DIR/step35-gitlab_create_group.sh
$CUR_DIR/step36-gitlab_create_group_runner.sh

finish_banner $S_TIME
