#!/bin/sh

CUR_DIR=$(cd $(dirname $0); pwd)
. $CUR_DIR/functions.sh

call_show_start_banner

echo "\n### START: Install Open JDK ##########"
which java
if [ $? -ne 0 ]; then
	sudo apt install -y openjdk-21-jdk-headless
fi

call_show_finish_banner
