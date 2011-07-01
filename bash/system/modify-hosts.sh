#!/bin/bash

HOSTSFILE=/etc/hosts

function usage() {
	echo $"Usage: ./modify_hosts.sh [-arhfvn <domain> [<match> <ip|127.0.0.1>]]"
}
function read-user-input {
    read response
    if [ "x$response" != x"" ]; then
        eval $1=$response
    else
        eval $1=$2
    fi
}
function add_hosts() {
	if [ "x$2" == x"" ]; then echo "You must supply a domain name to add!"; usage; exit 1; fi
	if [ "$3" == "NIL" ]; then
		if [ "$1" == "1" ]; then
			cat $HOSTSFILE; echo -e "$4\t\t $2 "
		else
			sudo echo -e "$4\t\t $2 " | sudo tee -a $HOSTSFILE 1>/dev/null
		fi
	else
		if [ "$1" == "1" ]; then
			cat $HOSTSFILE | sed "s|$4\t\t\(.*\)$3 |$4\t\t\1$3 $2 |"
		else
			cat $HOSTSFILE | sed "s|$4\t\t\(.*\)$3 |$4\t\t\1$3 $2 |" | sudo tee $HOSTSFILE 1>/dev/null
		fi
	fi
}
function remove_hosts() {
	if [ "x$2" == x"" ]; then echo "You must supply a domain name to remove!"; usage; exit 1; fi
	if [ "$1" == "1" ]; then
		cat $HOSTSFILE | sed "s| $2 | |"
	else
		cat $HOSTSFILE | sed "s| $2 | |" | sudo tee $HOSTSFILE  1>/dev/null
	fi
}

while getopts ":farvnh" options
do
  case $options in
	f)
		CONFIRM_CHANGE=0
		;;
	a)
		ADD_HOSTS=1
		;;
	r)
		REMOVE_HOSTS=1
		;;
	v)
		DUMP_HOSTS=1
		;;
	n)
		DRY_RUN=1
		;;
	h)
		usage
		exit 1;
		;;
	*)
		usage
		exit 1;
		;;
  esac
done
shift $(($OPTIND - 1))

DOMAIN=$1
MATCH=${2:-"NIL"}
IPADDR=${3:-"127.0.0.1"}

ADD_HOSTS=${ADD_HOSTS:-0}
REMOVE_HOSTS=${REMOVE_HOSTS:-0}
CONFIRM_CHANGE=${CONFIRM_CHANGE:-1}
DUMP_HOSTS=${DUMP_HOSTS:-0}
DRY_RUN=${DRY_RUN:-0}

if [ "$ADD_HOSTS" == "1" ]; then
	if [ "$CONFIRM_CHANGE" == "1" ]; then
		echo "Add '$DOMAIN' near '$MATCH' for IP: '$IPADDR' in /etc/hosts file? [ yes|no ]"
		read-user-input response no
	fi
	if [ "$response" == "yes" ] || [ "$response" == "y" ] || [ "$CONFIRM_CHANGE" == "0" ]; then
		add_hosts $DRY_RUN $DOMAIN $MATCH $IPADDR
	else
		echo "No changes done!"
	fi
fi

if [ "$REMOVE_HOSTS" == "1" ]; then
	if [ "$CONFIRM_CHANGE" == "1" ]; then
		echo "Remove '$DOMAIN' from /etc/hosts file? [ yes|no ]"
		read-user-input response no
	fi
	if [ "$response" == "yes" ] || [ "$response" == "y" ] || [ "$CONFIRM_CHANGE" == "0" ]; then
		remove_hosts $DRY_RUN $DOMAIN
	else
		echo "No changes done!"
	fi
fi

if [ "$DUMP_HOSTS" == "1" ] && [ "$DRY_RUN" == "0" ]; then
	cat /etc/hosts;
fi

if [ "$(($OPTIND))" == "1" ]; then usage; fi
