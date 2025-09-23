#!/bin/sh

S_TIME=$(date +%s)
CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh
. $CUR_DIR/variables.sh

DWN_DIR=$(prepare_download_dir $CUR_DIR)

case "$1" in
	"up")
		clear
		start_banner

		get_dependencytrack_yaml $CUR_DIR $DEPT_YAML_URL $DEPT_YAML_FIL
		prepare_deptrack_server_name $CUR_DIR $DEPT_YAML_FIL \
			$DEPT_APIS_NM_BEF $DEPT_APIS_NM_AFT \
			$DEPT_FRNT_NM_BEF $DEPT_FRNT_NM_AFT \
			$DEPT_PSQL_NM_BEF $DEPT_PSQL_NM_AFT
		prepare_deptrack_port_number $CUR_DIR $DEPT_YAML_FIL \
			$DEPT_APIS_PORT_BEF $DEPT_APIS_PORT_AFT \
			$DEPT_FRNT_PORT_BEF $DEPT_FRNT_PORT_AFT
		insert_deptrack_container_name $CUR_DIR $DEPT_YAML_FIL \
			$DEPT_APIS_NM_AFT $DEPT_FRNT_NM_AFT $DEPT_PSQL_NM_AFT

		get_jfrog_oss_package $DWN_DIR $ARTF_PKG_URL $ARTF_PKG_PTN
		prepare_jfrog_oss_files $CUR_DIR $DWN_DIR $ARTF_DIR_PTN
		clean_jfrog_oss_package $DWN_DIR $ARTF_PKG_PTN $ARTF_DIR_PTN

		get_webapp_package $DWN_DIR $WEBAPP_PKG_URL
		prepare_webapp_mysql_files $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL
		clean_webapp_package $DWN_DIR $WEBAPP_PKG_URL

		create_container $CUR_DIR
		join_to_network

		show_list_container
		show_url
		show_command
		finish_banner $S_TIME
		;;
	"up-exporter")
		clear
		start_banner
		create_container_exporter $CUR_DIR
		show_list_container
		finish_banner $S_TIME
		;;
	"down")
		clear
		start_banner
		destory_container $CUR_DIR
		show_list_container
		finish_banner $S_TIME
		;;
	"rebuild")
		clear
		start_banner
		rebuild_container $CUR_DIR $2
		clear_ssh_known_hosts
		show_list_container
		finish_banner $S_TIME
		;;
	"list")
		clear
		show_list_container
		;;
	"info")
		show_url
		show_password
		show_information
		;;
	"")
		clear
		start_banner
		destory_container $CUR_DIR

		get_dependencytrack_yaml $CUR_DIR $DEPT_YAML_URL $DEPT_YAML_FIL
		prepare_deptrack_server_name $CUR_DIR $DEPT_YAML_FIL \
			$DEPT_APIS_NM_BEF $DEPT_APIS_NM_AFT \
			$DEPT_FRNT_NM_BEF $DEPT_FRNT_NM_AFT \
			$DEPT_PSQL_NM_BEF $DEPT_PSQL_NM_AFT
		prepare_deptrack_port_number $CUR_DIR $DEPT_YAML_FIL \
			$DEPT_APIS_PORT_BEF $DEPT_APIS_PORT_AFT \
			$DEPT_FRNT_PORT_BEF $DEPT_FRNT_PORT_AFT
		insert_deptrack_container_name $CUR_DIR $DEPT_YAML_FIL \
			$DEPT_APIS_NM_AFT $DEPT_FRNT_NM_AFT $DEPT_PSQL_NM_AFT

		get_jfrog_oss_package $DWN_DIR $ARTF_PKG_URL $ARTF_PKG_PTN
		prepare_jfrog_oss_files $CUR_DIR $DWN_DIR $ARTF_DIR_PTN
		clean_jfrog_oss_package $DWN_DIR $ARTF_PKG_PTN $ARTF_DIR_PTN

		get_webapp_package $DWN_DIR $WEBAPP_PKG_URL
		prepare_webapp_mysql_files $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL
		clean_webapp_package $DWN_DIR $WEBAPP_PKG_URL

		create_container $CUR_DIR
		join_to_network

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
