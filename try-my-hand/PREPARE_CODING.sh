#!/bin/sh

S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

DWN_DIR=$(prepare_download_dir $CUR_DIR)

clear
start_banner

echo "\n### START: Get a package for webapp"
get_webapp_package $DWN_DIR $WEBAPP_PKG_URL

echo "\n### START: Clone gitlab repository with branch"
clone_gitlab_repo_with_branch "$CUR_DIR" "$DWN_DIR" "$WEBAPP_PKG_URL" "$WEBAPP_PROJECTS"

echo "\n### START: Clean up a package for webapp"
clean_webapp_package $DWN_DIR $WEBAPP_PKG_URL

finish_banner $S_TIME
