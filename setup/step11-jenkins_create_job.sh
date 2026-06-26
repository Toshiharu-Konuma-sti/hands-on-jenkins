#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/common.sh
. $CUR_DIR/custom.sh
. $CUR_DIR/variables.sh

call_show_start_banner

JENK_CLI_DIR=$(prepare_download_dir $CUR_DIR)
JENK_CLI_PATH=$JENK_CLI_DIR/$JENK_CLI_JAR

get_jenkins_cli ${JENK_CLI_PATH} ${JENK_HOST_EXT} ${JENK_CLI_JAR}
FILE_LIST=$(listing_jenkins_job_config ${CUR_DIR})
import_jenkins_job ${JENK_CLI_PATH} ${JENK_HOST_EXT} ${JENK_USER} ${JENK_PASS} ${JENK_JOB_TOKEN} "${FILE_LIST}"
remove_jenkins_cli $JENK_CLI_PATH

call_show_finish_banner
