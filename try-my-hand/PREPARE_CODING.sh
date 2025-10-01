#!/bin/sh

S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

DWN_DIR=$(prepare_download_dir $CUR_DIR)

clear
start_banner

$CUR_DIR/step01-clone_gitlab_repo.sh
$CUR_DIR/step02-move_webapp_codes_to_repo.sh

finish_banner $S_TIME
