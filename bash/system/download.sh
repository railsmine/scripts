#!/bin/bash
#
# RANDOM DOWNLOAD SCRIPT I MADE FOR PASSING SOME TIME AND ENHANCING MY BASH SCRIPTING KNOWLEDGE
# TODO: display download size
# TODO: allow add/remove of download urls via command line
# TODO: display error when md5sum doesnt match for downloaded file
#
SCRIPTNAME=$(basename "$0")
JUKEBOX=/media/JukeBox
DOWNLOAD_DIRS=( "$HOME/Downloads" "$JUKEBOX/Downloads" "$JUKEBOX/Softwares" "$JUKEBOX/iso" )

function error { show_success 0 "failed" "$1"; }
function warn { show_success 1 "warning" "$1"; }
function success { show_success 2 "success" "$1"; }
function die { show_success 3 "aborted" "$1"; exit 999; }
function log { show_success 4 "info" "$1"; }

function show_success() {
	# Parameters: condition_check (0|1|2|3|4), warn|fail|success|abort|log, [desc]
	# Parameters: condition_check (0|1|2|3|4), message, [desc]
    message=( $(echo "$2" | tr '|' ' ') ); message="${message[$1]}"; message=${message:-"$2"}
    color=( "${RED}" "${YLW}" "${GRN}" "${RED}" "${NML}" )
    if (( $COLORCODES )); then desc="${color[$1]}$3${NML}" ; else desc="${desc[$1]}! $3"; fi
    [ -n "$3" ] && echo -ne "${desc}";
    if (( $COLORCODES )); then tput hpa $COL; echo -e "${color[$1]}[ ${message} ]${NML}";
    else printf "\n%${COL}s\n" "...[ ${message} ]"; fi
}
function check_requirements() {
    type -P wget &>/dev/null || die "I require 'wget' but it's not installed."
    type -P sed  &>/dev/null || die "I require 'sed'  but it's not installed."
    type -P grep &>/dev/null || die "I require 'grep' but it's not installed."
    type -P md5sum &>/dev/null || die "I require 'md5sum' but it's not installed."
    [ -f "$DOWNLOAD_QUEUE" ] || die "I cannot find the download queue."
    [ -d "$JUKEBOX/Downloads" ] || die "I cannot find existing downloads, unless JukeBox is mounted!"
}
function usage() {
    echo $"Usage:
    download [-h0avq] [-d download_queue_file] [-n download_number]"
    exit 900;
}
function startdownloads() {
    FILENAME="$1"; DOWNLOADNO="$DOWNLOADNO";
    cat $FILENAME | while read line; do
        data=( $line )
        data=( "${data[@]}" "$(basename "${data[4]}")" )
        if [ "${data[0]}" != "ZZ" ] || [[ -z $DOWNLOADNO || $DOWNLOADNO == ${data[1]} ]] || [ -z "$DOWNLOADNO" ] ; then
            # check the status for this download
            check_status "${data[1]}" "${data[4]}" "${data[3]}"
            #echo "${STATUS[*]}"
            # if not yet downloaded or if partial, download this file
            if [ "${STATUS[0]}" == "--" ] || [ "${STATUS[0]}" == "PT" ]; then
                downloadfile "${data[*]}" "${STATUS[1]}"
            fi
        fi
        if [[ $DOWNLOADNO != 0 && $DOWNLOADNO == ${data[1]} ]] || [ -z "$DOWNLOADNO" ]; then
        # update the status of this file
        update_status "${data[*]}" "${STATUS[1]}"
        fi
    done
}
function check_status() {
    # Parameters: prevstatus, fileurl, md5sum
    # Checks: status for this download
    # -- -> yet to start the download
    # XX -> Invalid MD5 Checksum
    # PT -> Partial (downloading)
    # UK -> Unknown (no md5sum to verify with)
    # DW -> Just been downloaded
    # OK -> Completed and MD5 checksum verified
    # ZZ -> Removed from Download Queue
    # ER -> Error in download
    
    SERIAL="$1"; FILEURL="$2"; FILENAME="$(basename $2)"; MD5STR="$3"; STATUS=""
    PREVSTATUS="$(cat $DOWNLOAD_QUEUE | grep "^..[ ]*${SERIAL}.*${FILEURL}" | cut -f1 -d' ')"
    for downdirs in ${DOWNLOAD_DIRS[@]}; do
        mkdir -p "$downdirs"
        [ -n "$STATUS" ] || STATUS="$(find "$downdirs" -type f -iname "$FILENAME")"
    done
    if [ -z "$STATUS" ]; then
        STATUS="$PREVSTATUS|"
    elif [ "$(md5sum $STATUS | cut -f1 -d' ')" == "$MD5STR" ]; then
                STATUS="OK|$STATUS"
    elif [ "$MD5STR" == "--NONE--" ] && [ "$PREVSTATUS" == "DW" ]; then
                STATUS="UK|$STATUS"
    elif [ "$PREVSTATUS" == "DW" ]; then
                STATUS="XX|$STATUS"
    else
        STATUS="$PREVSTATUS|$STATUS"
    fi
    STATUS=( $(echo "$STATUS" | tr '|' ' ') )
    if [ "${STATUS[0]}" == "OK" ]; then return 0; else return 1; fi
}
function downloadfile() {
    data=( $1 )
    if [ -n "$2" ]; then direxists="$(dirname $2)"; else direxists="${DOWNLOAD_DIRS[0]}"; fi
    echo -e "Downloading: ${data[2]}"
    if WGET "${data[4]}" "$direxists"; then
        success "Downloaded: ${data[2]}"
        sed -i -e "s|^..\(.*${data[1]}.*${data[2]}\)|DW\1|" "$DOWNLOAD_QUEUE"
    else
        sed -i -e "s|^..\(.*${data[1]}.*${data[2]}\)|ER\1|" "$DOWNLOAD_QUEUE"
    fi
}
function update_status() {
    data=( $1 )
    direxists=$(dirname "$2")
    check_status "${data[1]}" "${data[4]}" "${data[3]}"
    if (( $SHOWALL)); then
          if [ "${STATUS[0]}" == "--" ]; then log "${data[1]}) Yet to start downloading of: ${BLU}${data[2]}${NML}";
        elif [ "${STATUS[0]}" == "PT" ]; then log "${data[1]}) Partially downloaded: ${BLU}${data[2]}${NML}";
        elif [ "${STATUS[0]}" == "DW" ]; then success "${data[1]}) Just finished downloading: ${BLU}${data[2]}${GRN}";
        elif [ "${STATUS[0]}" == "OK" ] && [ "${data[1]}" != "DW" ]; then log "${data[1]}) ${BLU}${data[2]}${NML} exists in directory: $2";
        fi
    fi
    if [ "${STATUS[0]}" == "XX" ]; then error "${data[1]}) MD5 Checksum failed for: ${BLU}${data[2]}${RED}"; fi
    if [ "${STATUS[0]}" == "UK" ]; then warn "${data[1]}) Downloaded: ${BLU}${data[2]}${YLW}.. No MD5 Checksum to compare against!"; fi
    if [ "${STATUS[0]}" == "ER" ]; then error "${data[1]}) Did not download: ${BLU}${data[2]}${RED}, due to errors encountered previously!"; fi
    if [ "${data[1]}" == "DW" ] && [ "${STATUS[0]}" == "OK" ]; then success "${data[1]}) Just finished downloading: ${BLU}${data[2]}${GRN}"; fi
    if [ "${STATUS[0]}" == "ZZ" ]; then warn "${data[1]}) ${BLU}${data[2]}${YLW} was ignored from download queue!"; fi
    
    sed -i -e "s|^..\(.*${data[1]}.*${data[2]}\)|${STATUS[0]}\1|" "$DOWNLOAD_QUEUE"       
}
function WGET() {
    WGET="wget --timeout=5 --tries=5 --continue --timestamping --progress=bar --directory-prefix=$2 $1"
    
      if (( $VERBOSE )); then $WGET --verbose;
    elif (( $QUIETMODE )); then $WGET --quiet;
    else $WGET --no-verbose;
      fi
}

while getopts ":0havqn:d:" options
do
  case $options in
    0) COLORCODES=0;;
    d) DOWNLOAD_QUEUE="$OPTARG";;
    a) SHOWALL=1;;
    v) VERBOSE=0;;
    q) QUIETMODE=1;;
    n) DOWNLOADNO="$OPTARG";;
    h|*) SHOWUSAGE=1;;
  esac
done
shift $(($OPTIND - 1))

COLORCODES=${COLORCODES:-1}
DOWNLOAD_QUEUE=${DOWNLOAD_QUEUE:-"$HOME/download-queue"}
SHOWALL=${SHOWALL:-0}
SHOWUSAGE=${SHOWUSAGE:-0}
VERBOSE=${VERBOSE:-1}
QUIETMODE=${QUIETMODE:-0}
DOWNLOADNO=${DOWNLOADNO:-""}

# define some constants
(( $COLORCODES )) && BLD=$(tput bold)
(( $COLORCODES )) && NML=$(tput sgr0)
(( $COLORCODES )) && RED=$BLD$(tput setaf 1)
(( $COLORCODES )) && GRN=$BLD$(tput setaf 2)
(( $COLORCODES )) && YLW=$(tput setaf 3)
(( $COLORCODES )) && BLU=$(tput setaf 6)
COL=$(tput cols); let COL=COL-16

(( "$SHOWUSAGE" )) && usage

check_requirements
startdownloads "$DOWNLOAD_QUEUE" "$DOWNLOADNO"
echo -e "\n\t${BLU}${BLD}Completed.${NML}\n"
