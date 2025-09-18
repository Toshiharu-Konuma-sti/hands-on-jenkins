#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

call_show_start_banner

JK_CLI_JAR=jenkins-cli.jar
JK_CLI_DIR=$(prepare_download_dir $CUR_DIR)
JK_CLI_PATH=$JK_CLI_DIR/$JK_CLI_JAR

echo "\n### START: get a jenkins cli"

wget -O $JK_CLI_PATH http://$JK_HOST_EXT/jnlpJars/$JK_CLI_JAR

echo "\n### START: create build jobs to Jenkins"

for MY_PROJ in $WEBAPP_PROJECTS; do
	java -jar $JK_CLI_PATH -s http://$JK_HOST_EXT/ -auth $JK_USER:$JK_PASS create-job build-$MY_PROJ < $CUR_DIR/jenkins/jobs/config-build-$MY_PROJ.xml
done

echo "\n### START: create deploy job to Jenkins"

java -jar $JK_CLI_PATH -s http://$JK_HOST_EXT/ -auth $JK_USER:$JK_PASS create-job deploy-webapp < $CUR_DIR/jenkins/jobs/config-deploy-webapp.xml
java -jar $JK_CLI_PATH -s http://$JK_HOST_EXT/ -auth $JK_USER:$JK_PASS create-job deploy-webapp-with-grafana < $CUR_DIR/jenkins/jobs/config-deploy-webapp-with-grafana.xml

echo "\n### START: remove a jenkins cli"

rm -f $JK_CLI_PATH

call_show_finish_banner
