#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/common.sh

call_show_start_banner

check_required_commands "java jq"

call_show_finish_banner
