#!/bin/bash
#
# Proxy Switcher
#
# proxy-switch <id>

# === HEAVY LIFTING ===
shopt -s extglob

mkdir -p ~/.proxy
PROXYCONFIG=~/.proxy/config

# CURRENTIP=`curl -q http://icanhazip.com`
if [ "x$1" == x"" ]; then PROXY="0"; else PROXY="$1"; fi
PROXYIP=( "" "173.199.131.200" "173.199.131.201" "173.199.131.202" "173.199.131.203" )
PROPORT=( 0 3128 3128 3128 3128 )
IGNOREHOSTS=["localhost","127.0.0.0/8","*.local","*.n","ldev","localdev","localserver","local","wiredtree","vps","server","liveserver","gitserver","git-server"]

function proxy_exists() {
	if [ "$1" == "1" ] || [ "$1" == "2" ] || [ "$1" == "3" ] || [ "$1" == "4" ]; then echo "$1";
	elif [ "$1" == "0" ] || [ "x$1" == x"" ]; then echo "0";
	else echo "99";
	fi
}
function get_proxy() {
	PROXY=`gconftool-2 -g /system/proxy/mode`
	if [ "$PROXY" == "manual" ]; then
		PROXY=`gconftool-2 -g /system/http_proxy/host`
		CURRENTIP=`curl -s http://icanhazip.com`
		USING_PROXY=0
		for i in 0 1 2 3 4; do
			if [ "$CURRENTIP" == "${PROXYIP[$i]}" ]; then USING_PROXY="${PROXYIP[$i]}:${PROPORT[$i]}"; fi
		done
		#echo "IP: $CURRENTIP | PROXY: $USING_PROXY"
		if [ "x$USING_PROXY" == x"" ] || [ "$USING_PROXY" == "0" ] ; then echo "Directly Connected to Internet (no proxy)";
		else echo "Connected using proxy: $USING_PROXY";
		fi
	elif [ "$PROXY" == "none" ] || [ "x$PROXY" == x"" ]; then echo "Directly Connected to Internet (no proxy)";
	else echo "You seem to be using a direct connection!";
	fi
}
function usage() {
	SET_PROXY=0
	echo "Usage:
	proxy-switch [-hvlg] [-s {0|1|2|3|4}]";
}
function show_proxy() {
	PROXY=$(proxy_exists $1)
	if [ "$PROXY" == "99" ]; then echo "Invalid Proxy";
	elif [ "$PROXY" == "0" ]; then echo "$PROXY	No Proxy";
	else echo "$PROXY	${PROXYIP[$1]}:${PROPORT[$1]}";
	fi
}
function switch_proxy() {
	PROXY=$(proxy_exists $1)
	if [ "$PROXY" == "99" ]; then echo "Invalid Proxy Configuration! Could not switch proxy!"; exit 99; fi
	if [ "$PROXY" == "0" ]; then PROXY=false; else PROXY=true; fi

	gconftool-2 --type=string -s /system/proxy/old_ftp_host "`gconftool-2 -g /system/proxy/ftp_host`"
	gconftool-2 --type=int    -s /system/proxy/old_ftp_port `gconftool-2 -g /system/proxy/ftp_port`
	gconftool-2 --type=string -s /system/proxy/old_secure_host "`gconftool-2 -g /system/proxy/secure_host`"
	gconftool-2 --type=int    -s /system/proxy/old_secure_port `gconftool-2 -g /system/proxy/secure_port`
	gconftool-2 --type=string -s /system/proxy/old_socks_host "`gconftool-2 -g /system/proxy/socks_host`"
	gconftool-2 --type=int    -s /system/proxy/old_socks_port `gconftool-2 -g /system/proxy/socks_port`

	gconftool-2 --type=string -s /system/proxy/autoconfig_url ""
	gconftool-2 --type=int    -s /system/proxy/ftp_port ${PROPORT[$1]}
	gconftool-2 --type=int    -s /system/proxy/secure_port ${PROPORT[$1]}
	gconftool-2 --type=string -s /system/proxy/secure_host "${PROXYIP[$1]}"
	gconftool-2 --type=string -s /system/proxy/socks_host "${PROXYIP[$1]}"
	gconftool-2 --type=int    -s /system/proxy/socks_port ${PROPORT[$1]}
	gconftool-2 --type=string -s /system/proxy/ftp_host "${PROXYIP[$1]}"
	
	gconftool-2 --type=bool   -s /system/http_proxy/use_same_proxy $PROXY	
	gconftool-2 --type=bool   -s /system/http_proxy/use_http_proxy $PROXY
	gconftool-2 --type=bool   -s /system/http_proxy/use_authentication $PROXY
	gconftool-2 --type=string -s /system/http_proxy/host "${PROXYIP[$1]}"
	gconftool-2 --type=list   -s /system/http_proxy/ignore_hosts $IGNOREHOSTS --list-type=string

	if [ "$PROXY" == "false" ]; then
		gconftool-2 --type=string -s /system/proxy/mode "none"
		gconftool-2 --type=int    -s /system/http_proxy/port 8080
		gconftool-2 --type=string -s /system/http_proxy/authentication_password ""
		gconftool-2 --type=string -s /system/http_proxy/authentication_user ""
		
		echo 'export ALL_PROXY=""' > $PROXYCONFIG;
	else
		gconftool-2 --type=string -s /system/proxy/mode "manual"
		gconftool-2 --type=int    -s /system/http_proxy/port ${PROPORT[$1]}
		gconftool-2 --type=string -s /system/http_proxy/authentication_password "PASSWORD"
		gconftool-2 --type=string -s /system/http_proxy/authentication_user "nikhgupta"
		echo "export ALL_PROXY='http://nikhgupta:PASSWORD@${PROXYIP[$1]}:${PROPORT[$1]}';" > $PROXYCONFIG;
	fi
	# source $PROXYCONFIG;
	PROXY=$(show_proxy $1); PROXY=`echo $PROXY | tr "\t" " " | cut -f2- -d" "`
	echo "Switched to: $PROXY"
}
while getopts ":hvgls" options
do
  case $options in
    h) # show usage help
	usage
	exit 1;
	;;
    v) # verbose mode.. display gconf-keys after switching
	SHOW_GCONF_KEYS=1
	;;
    g) # print current proxy
	get_proxy
	;;
    l) # show available proxies
	SET_PROXY=0;	
	echo "ID	Proxy";
	echo "============================"
        for i in 0 1 2 3 4; do
		show_proxy $i
	done
	echo "============================"
	exit 1;
	;;
    s)
	SET_PROXY=1
	;;
    *)
	if [ "$SET_PROXY" != "0" ]; then usage; fi
	exit 1;
	;;
  esac
done
shift $(($OPTIND - 1))
SET_PROXY=${SET_PROXY:-0}
SHOW_GCONF_KEYS=${SHOW_GCONF_KEYS:-0}

if [ $(($OPTIND)) == 1 ]; then echo;get_proxy; echo; usage; fi
if [ $SET_PROXY == 1 ]; then switch_proxy $1; fi
if [ $SHOW_GCONF_KEYS == 1 ]; then gconftool-2 -R /system/proxy && echo && gconftool-2 -R /system/http_proxy; fi
