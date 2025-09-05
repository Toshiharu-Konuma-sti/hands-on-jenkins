#!/bin/sh

S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

DWN_DIR=$(prepare_download_dir $CUR_DIR)

clear
start_banner

echo "\n### START: get a package for webapp"
get_webapp_package $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL

echo "\n### START: preaper gitlab repository with branch"
prepare_gitlab_repo_with_branch "$CUR_DIR" "$DWN_DIR" "$WEBAPP_PKG_URL" "$WEBAPP_PROJECTS"

echo "\n### START: clean up a package for webapp"
clean_webapp_package $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL

finish_banner $S_TIME
