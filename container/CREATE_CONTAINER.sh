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

		get_jfrog_oss_package $CUR_DIR $DWN_DIR $ART_PKG_URL $ART_PKG_PTN
		prepare_jfrog_oss_files $CUR_DIR $DWN_DIR $ART_DIR_PTN
		clean_jfrog_oss_package $CUR_DIR $DWN_DIR $ART_PKG_PTN $ART_DIR_PTN

		get_webapp_package $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL
		prepare_webapp_mysql_files $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL
		clean_webapp_package $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL

		create_container
		join_to_network
		show_list_container
		show_url
		finish_banner $S_TIME
		;;
	"up-exporter")
		clear
		start_banner
		create_container_exporter
		finish_banner $S_TIME
		;;
	"down")
		clear
		start_banner
		destory_container
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
	"rebuild")
		clear
		rebuild_container $2
		;;
	"")
		clear
		start_banner
		destory_container

		get_jfrog_oss_package $CUR_DIR $DWN_DIR $ART_PKG_URL $ART_PKG_PTN
		prepare_jfrog_oss_files $CUR_DIR $DWN_DIR $ART_DIR_PTN
		clean_jfrog_oss_package $CUR_DIR $DWN_DIR $ART_PKG_PTN $ART_DIR_PTN

		get_webapp_package $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL
		prepare_webapp_mysql_files $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL
		clean_webapp_package $CUR_DIR $DWN_DIR $WEBAPP_PKG_URL

		create_container
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
