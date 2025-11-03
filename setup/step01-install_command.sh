#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh

call_show_start_banner

install_required_tools_for_setup

call_show_finish_banner
