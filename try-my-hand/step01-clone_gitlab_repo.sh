#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. "${CUR_DIR}/common.sh"
. "${CUR_DIR}/custom.sh"
. "${CUR_DIR}/variables.sh"

DWN_DIR=$(prepare_download_dir "${CUR_DIR}")

call_show_start_banner

clone_gitlab_repo_with_branch "${CUR_DIR}" "${DWN_DIR}" "${GITL_HOST}" "${GITL_GRP_PATH}" "${WEBAPP_PROJECTS}"

call_show_finish_banner
