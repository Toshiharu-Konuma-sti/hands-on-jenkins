#!/bin/sh

# {{{ The_Steps_Of_Creating_Containers()
The_Steps_Of_Creating_Containers()
{
	get_dependencytrack_yaml $CUR_DIR $DTRK_YAML_URL $DTRK_YAML_FIL
	replace_dtrack_port_number $CUR_DIR $DTRK_YAML_FIL \
		$DTRK_APIS_PORT_BEF $DTRK_APIS_PORT_AFT \
		$DTRK_FRNT_PORT_BEF $DTRK_FRNT_PORT_AFT

	get_jfrog_oss_package $DWN_DIR $ARTF_PKG_URL $ARTF_PKG_PTN
	move_jfrog_oss_files $CUR_DIR $DWN_DIR $ARTF_DIR_PTN
	clean_jfrog_oss_package $DWN_DIR $ARTF_PKG_PTN $ARTF_DIR_PTN

	get_webapp_package $DWN_DIR $WEBAPP_PKG_URL
	move_webapp_mysql_files $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL
	clean_webapp_package $DWN_DIR $WEBAPP_PKG_URL

	create_container $CUR_DIR
}
# }}}

S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/common.sh
. $CUR_DIR/custom.sh
. $CUR_DIR/variables.sh

DWN_DIR=$(prepare_download_dir $CUR_DIR)

case "$1" in
	"up")
		clear
		start_banner
		check_required_commands "docker unzip"

		The_Steps_Of_Creating_Containers

		show_list_container
		show_url
		show_command
		finish_banner $S_TIME
		;;
	"up-exporter")
		clear
		start_banner
		check_required_commands "docker"
		create_container_exporter $CUR_DIR
		show_list_container
		finish_banner $S_TIME
		;;
	"down")
#		clear
		start_banner
		check_required_commands "docker"
		destory_container $CUR_DIR
		show_list_container
		finish_banner $S_TIME
		;;
	"rebuild")
#		clear
		start_banner
		check_required_commands "docker"
		rebuild_container $CUR_DIR $2
		clear_ssh_known_hosts
		show_list_container
		finish_banner $S_TIME
		;;
	"list")
#		clear
		show_list_container
		;;
	"info")
		show_url
		show_password
		show_information
		;;
	"")
#		clear
		start_banner
		check_required_commands "docker unzip"

		destory_container $CUR_DIR

		The_Steps_Of_Creating_Containers

		show_list_container
		show_url
		show_command
		finish_banner $S_TIME
		;;
	*)
		show_usage
		exit 1
		;;
esac
