#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

DWN_DIR=$(prepare_download_dir $CUR_DIR)

call_show_start_banner

get_webapp_package $DWN_DIR $WEBAPP_PKG_URL

move_webapp_codes_to_repo "$CUR_DIR" "$DWN_DIR" "$WEBAPP_PKG_URL" "$WEBAPP_PROJECTS"

clean_webapp_package $DWN_DIR $WEBAPP_PKG_URL

call_show_finish_banner
