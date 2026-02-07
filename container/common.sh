
# {{{ start_banner()
start_banner()
{
	echo "############################################################"
	echo "# START SCRIPT"
	echo "############################################################"
}
# }}}

# {{{ finish_banner()
# $1: time to start this script
finish_banner()
{
	S_TIME=$1
	E_TIME=$(date +%s)
	DURATION=$((E_TIME - S_TIME))
	echo "############################################################"
	echo "# FINISH SCRIPT ($DURATION seconds)"
	echo "############################################################"
}
# }}}

# {{{ call_own_fname()
call_own_fname()
{
	OFNM=$(basename $0)
	echo "$OFNM"
}
# }}}

# {{{ call_show_start_banner()
# $0: the name of the script being executed 
call_show_start_banner()
{
	echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n> START: Script = [$(call_own_fname)]\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}
# }}}

# {{{ call_show_finish_banner()
# $0: the name of the script being executed 
call_show_finish_banner()
{
	echo "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n< FINISH: Script = [$(call_own_fname)]\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
}
# }}}


# {{{ check_required_commands()
check_required_commands()
{
	echo "\n### START: Check required commands ##########"
	local missing_cmds=""
	for cmd in $*; do
		if ! command -v "${cmd}" >/dev/null 2>&1; then
			if [ -z "$missing_cmds" ]; then
				missing_cmds="${cmd}"
			else
				missing_cmds="${missing_cmds} ${cmd}"
			fi
		fi
	done
	if [ -n "$missing_cmds" ]; then
		echo "========================================================" >&2
		echo " [ERROR] The following required commands are missing." >&2
		echo " Please install them or check your PATH to continue." >&2
		echo "========================================================" >&2
		for missing in $missing_cmds; do
			echo " - ${missing}" >&2
		done
		echo "" >&2
		exit 1
	fi
}
# }}}


# {{{ loop_curl_until_success()
# $1: the command to call with cURL
loop_curl_until_success()
{
	CMD_CURL=$1
	echo "$CMD_CURL" >&2
	BODY_CURL=""
	WAIT_SEC=5
	while true; do
		BODY_CURL=$(eval $CMD_CURL)
		if [ $? -eq 0 ]; then
			echo "-> result: connection successful." >&2
			break
		else
			echo "-> result: connection failed. will try again in $WAIT_SEC seconds." >&2
			sleep $WAIT_SEC
		fi
	done
	echo "$BODY_CURL" >&2
	echo "$BODY_CURL"
}
# }}}

# {{{ prepare_download_dir()
# $1: the current directory
prepare_download_dir()
{
	CUR_DIR=$1
	DOWN_DIR=$CUR_DIR/../download
	mkdir -p $DOWN_DIR
	echo $DOWN_DIR
}
# }}}


# {{{ show_list_container()
show_list_container()
{
	echo "\n### START: Show a list of container ##########"
	docker ps -a
}
# }}}
