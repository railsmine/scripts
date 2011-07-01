#!/bin/bash

NOTEBOOKDIR=$1
KEYWORD="$2"
KEYWORD=${KEYWORD,,}

LOGFILE=$1/WordPress_Sync_Log.txt
CONFIGFILE=$1/wp-export.passwd

# define some very basic functions
fileecho()  { (( "$2" )) || echo -ne "* " | tee -a $LOGFILE; echo -e "$1" 2>&1 | tee -a $LOGFILE; }
requirements() {
#    type -P md5sum  &>/dev/null || showerror "I require 'md5sum' but it's not installed."
#    type -P git     &>/dev/null || showerror "I require 'git' but it's not installed."
    type -P grep    &>/dev/null || showerror "I require 'grep'   but it's not installed."
    type -P zenity  &>/dev/null || NOZENITY=1
}
create_files() {
    # create a configuration file in our notebook directory, where we will save our passwords file
    [ -f $CONFIGFILE ] || {
        fileecho "Adding a Configuration file for CLI Poster in this notebook folder.."
        touch $CONFIGFILE
    }
}
showerror() {
    fileecho "**ERROR:** $1\n* **Aborting Sync..**"
    fileecho "============================================================\n" 1
    (( $NOZENITY )) || zenity --error --text="$1\nAborting Sync.." --title="Sync with Github"
    exit 0;
}
showinfo()  {
    fileecho "**$1**"
    fileecho "============================================================\n" 1
    (( $NOZENITY )) || zenity --info --text="$1" --title="Sync with Github"
}
get_file_name_and_extensions() {
    filename="${1##*/}";
    fileex="${filename#*.}"
    filename="${filename%%.*}"
    fileex=${fileex,,}
    if [ "$filename" == "$fileex" ] || [ -z "$filename" ]; then
        filename="$fileex";
        fileex="";
    fi
    filename="$(echo ${filename} | sed 's|[-_]| |g')"
    parent="$(dirname $1)"
    parent="$(echo ${parent##*/} | sed 's|[-_]| |g')"
    [ -n "${parent}" ] || parent="${filename}"
}
ask_for_wordpress_login() {
    WPCONFIG="$(<$CONFIGFILE)"
    [ -n "$WPCONFIG" ] || {
        WPURL=$( zenity --title "Sync with WordPress" --entry --text="Please, enter your WordPress Blog URL without http:// or https:// e.g. en.wordpress.org")
        WPUSER=$(zenity --title "Sync with WordPress" --entry --text="Please, enter your Username for blog at: http://$WPURL")
        WPPASS=$(zenity --title "Sync with WordPress" --entry --text="Please, enter your Password for blog at: http://$WPURL")
        
        fileecho "Checking blog settings.."
        CLIPOSTER -d $CONFIGFILE -a "${WPURL}:${WPUSER}:${WPPASS}:active" -x || showerror "An error has occured!"
    }
}
post_to_wordpress() {
    for i in $(find $NOTEBOOKDIR -iname "*.txt" -type f -not -iregex "$NOTEBOOKDIR.*\(Wordpress\|Git_Zim\)_Sync_Log\.txt"); do
        get_file_name_and_extensions $i;
        post_content="$(echo '$(<$i)' | tail -n +5)"
        
        fileecho "== Posting note: $filename ==" 1
        echo "${post_content}" | CLIPOSTER -d $CONFIGFILE  -s -f "text" -c "${parent}" -T "${filename}" || showerror "Could not post: '$filename.$fileex'"
    done
}
CLIPOSTER() {
    echo "'''" | tee -a $LOGFILE &>/dev/null
    bash /home/nikhgupta/Documents/scripts/bash/cli-poster/cli-poster.sh "$@" 2>&1 | tee -a $LOGFILE
    STATUS=${PIPESTATUS[0]}
    echo "'''" | tee -a $LOGFILE &>/dev/null
    return $STATUS
}

[ -f $LOGFILE ] || {
    CURRDATE="$(date +%F)T$(date +%T).$(date +%N | cut -b1-6)"
    echo -e "Content-Type: text/x-zim-wiki\nWiki-Format: zim 0.4\nCreation-Date: $CURRDATE\n" > $LOGFILE
    fileecho "====== WordPress Syncronization Log ======\n" 1 
}

fileecho "==== $(date -R) ====" 1

create_files
ask_for_wordpress_login
post_to_wordpress

sed -i -e "s|FATAL ERROR|\*\* FATAL ERROR \*\*|g" "s|Warning|\*\* Warning \*\*|g" $LOGFILE

showinfo "Sync Complete."
exit 0
