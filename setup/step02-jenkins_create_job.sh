#!/bin/sh

# {{{ get_jenkins_cli()
get_jenkins_cli()
{
	echo "\n### START: get a jenkins cli"
	JK_CLI_PATH=$1
	JK_HOST=$2
	JK_CLI_JAR=$3
	wget -O ${JK_CLI_PATH} http://${JK_HOST}/jnlpJars/${JK_CLI_JAR}
}
# }}}

# {{{ remove_jenkins_cli()
remove_jenkins_cli()
{
	echo "\n### START: remove a jenkins cli"
	JK_CLI_PATH=$1
	rm -f ${JK_CLI_PATH}
}
# }}}

# {{{ listing_jenkins_job_config()
listing_jenkins_job_config()
{
	CUR_DIR=$1
	FND_DIR="${CUR_DIR}/jenkins/jobs/"
	PATTERN="config-*.xml"
	FILE_LIST=$(find "${FND_DIR}" -type f -name "${PATTERN}")
	echo "${FILE_LIST}"
}
# }}}

# {{{ import_jenkins_job()
import_jenkins_job()
{
	JK_CLI_PATH=$1
	JK_HOST=$2
	JK_USER=$3
	JK_PASS=$4
	JK_JOB_TOKEN=$5
	F_LIST=$6

	echo "\n### START: create jobs to Jenkins"
	for F_PATH in ${F_LIST}
	do
		JOB_NAME=$(basename "${F_PATH}" | sed 's/^config-//; s/\.xml$//')
		echo ">>> register the '${JOB_NAME}' job"
		case "${JOB_NAME}" in
			build-*)
				sed "s|<secretToken>.*</secretToken>|<secretToken>${JK_JOB_TOKEN}</secretToken>|" ${F_PATH} | \
					java -jar ${JK_CLI_PATH} -s http://${JK_HOST}/ -auth ${JK_USER}:${JK_PASS} create-job ${JOB_NAME}
				;;
			*)
				java -jar ${JK_CLI_PATH} -s http://${JK_HOST}/ -auth ${JK_USER}:${JK_PASS} create-job ${JOB_NAME} < ${F_PATH}
				;;
		esac
	done
}
# }}}

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

call_show_start_banner

JENK_CLI_JAR=jenkins-cli.jar
JENK_CLI_DIR=$(prepare_download_dir $CUR_DIR)
JENK_CLI_PATH=$JENK_CLI_DIR/$JENK_CLI_JAR

get_jenkins_cli ${JENK_CLI_PATH} ${JENK_HOST_EXT} ${JENK_CLI_JAR}
FILE_LIST=$(listing_jenkins_job_config ${CUR_DIR})
import_jenkins_job ${JENK_CLI_PATH} ${JENK_HOST_EXT} ${JENK_USER} ${JENK_PASS} ${JENK_JOB_TOKEN} "${FILE_LIST}"
remove_jenkins_cli $JENK_CLI_PATH

call_show_finish_banner
