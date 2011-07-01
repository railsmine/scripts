#!/bin/bash

credits() {
    echo "Github Syncing for ZIM"
    echo "================================="
    echo "(c) Nikhil Gupta me@nikhgupta.com"
    echo "Version 1.0"
    echo "================================="
    echo -e "A tiny miny piece of bash magic\ncreate pure awesomeness.. ZIM is\nso absolutely amazin'..!!\n=================================="    
}

NOTEBOOKDIR=$1
KEYWORD="$2"
KEYWORD=${KEYWORD,,}
LOGFILE=$1/Git_Zim_Sync_Log.txt
GITIGNORE_FILES=".zim/ notebook.zim *.jpg *.png *.gif Git_Zim_Sync_Log.txt Wordpress_Sync_Log.txt wp-export.passwd"

# define some very basic functions
fileecho()  { (( "$2" )) || echo -ne "* " | tee -a $LOGFILE; echo -e "$1" 2>&1 | tee -a $LOGFILE; }
requirements() {
    type -P md5sum  &>/dev/null || showerror "I require 'md5sum' but it's not installed."
    type -P git     &>/dev/null || showerror "I require 'git' but it's not installed."
    type -P grep    &>/dev/null || showerror "I require 'grep'   but it's not installed."
    type -P zenity  &>/dev/null || NOZENITY=1
}
showerror() {
    fileecho "**ERROR:** $1\n* **Aborting Sync..**"
    fileecho "* ** rolling back... **"
    GITAPPEND reset --hard
    fileecho "============================================================\n" 1
    (( $NOZENITY )) || zenity --error --text="$1\nAborting Sync.." --title="Sync with Github"
    exit 0;
}
showinfo()  {
    fileecho "**$1**"
    fileecho "============================================================\n" 1
    (( $NOZENITY )) || zenity --info --text="$1" --title="Sync with Github"
}
md5string() { echo "$(date | md5sum | cut -b1-8)"; }

# GIT specific functions
GIT() {
    git --git-dir=$NOTEBOOKDIR/.git --work-tree=$NOTEBOOKDIR "$@"
}
GITAPPEND() {
    echo "'''" | tee -a $LOGFILE &>/dev/null
    git --git-dir=$NOTEBOOKDIR/.git --work-tree=$NOTEBOOKDIR "$@" 2>&1 | tee -a $LOGFILE
    STATUS=${PIPESTATUS[0]}
    echo "'''" | tee -a $LOGFILE &>/dev/null
    return $STATUS
}
sanitize_for_git() {
    # create a default README file.. users of this script are free to modify these credits..
    [ -f README -o -f README.md ] || {
        fileecho "Adding a README file for this Git repository.."
        credits | tee -a README &>/dev/null
    }
    
    # create a .gitignore file, which removes unncessary files from git versioning
    [ -f $NOTEBOOKDIR/.gitignore ] || {
        fileecho "Adding a .gitignore file for this Git repository.."
        touch $NOTEBOOKDIR/.gitignore
        set -x
        GITIGNORE_FILES=( "$GITIGNORE_FILES" )
        for i in ${GITIGNORE_FILES[@]}; do
            grep -q $i $NOTEBOOKDIR/.gitignore || echo $i >> $NOTEBOOKDIR/.gitignore
        done
        set +x
    }
}
get_github_remote() {
    GH_REMOTE=( $(GIT remote -v show | grep git@github.com | cut -f1 | sort -u) )
    [ "${#GH_REMOTE[@]}" -gt "1" ] && showerror "More than one Github remote tracking branches found!\nYou will need to manually remove these remote branches, first!"
    GH_REMOTE="${GH_REMOTE[0]}"
}
CURRDATE="$(date +%F)T$(date +%T).$(date +%N | cut -b1-6)"
[ -f $LOGFILE ] || {
    echo -e "Content-Type: text/x-zim-wiki\nWiki-Format: zim 0.4\nCreation-Date: $CURRDATE\n" > $LOGFILE
    fileecho "====== Git Zim Syncronization Log ======

'''
You can select one of the keywords below to alter the behaviour of the Sync with Github:
Keyword             Action
forced-push         Push to Github repository forcefully. (imitate: git push -f github master)
pull-remote         Pull from Github repository (imitate: git pull github master)
change-remote       Change remote Github repository (useful, if you entered a wrong repository url
                    will delete any existing github specific remote in this repository)
'''
" 1
}

# print current time of syncing for record purposes
fileecho "==== `date -R` ====" 1

# check our requirements
requirements

# sanitize things for git
sanitize_for_git

# get remote github branches already present
get_github_remote

# create a git repo if none found
[ -d $NOTEBOOKDIR/.git ] || {
    fileecho "Found no git repository for this notebook.. Creating one.."
    GITAPPEND init
}
# ask for github repo url if none found
[[ -n "$GH_REMOTE" && "$KEYWORD" != "change-remote" ]] || {
    if [ "$KEYWORD" == "change-remote" ]; then
        fileecho "Please, enter the new location of the Github Repository";
        NEWGITHUBREPOURL=$(zenity --title "Sync with Github" --entry --text="Please, enter the Github repository URL to sync with\ne.g. git@github.com:user/repository.git")
    else
        fileecho "Found no reference to a github repository.. Prompting..";
        NEWGITHUBREPOURL=$(zenity --title "Sync with Github" --entry --text="Could not find a reference to a github repository..\nPlease, enter the Github repository URL to sync with\ne.g. git@github.com:user/repository.git")
    fi
    fileecho "New Github Repository URL: '$NEWGITHUBREPOURL'"

    # abort if user did not enter a proper github url
    echo "$NEWGITHUBREPOURL" | grep -q "git@github.com:" || {
        showerror "Not a valid Github repository!\nGithub repository should be specified in the format:\ngit@github.com:user/repository.git"
    }

    # add this new github repo to our local repository as remote branch
    [ -n "$NEWGITHUBREPOURL" ] && {
        [ "$KEYWORD" == "change-remote" ] && {
            fileecho "Removing previous Github remotes.."
            GITAPPEND remote rm "$GH_REMOTE"
        }
        fileecho "Adding new Github repository as a remote branch for tracking purposes.."
        GITAPPEND remote add $(md5string) $NEWGITHUBREPOURL
    }

}

# add untracked files
fileecho "Adding untracked files, if any.."
GITAPPEND add $1

# create the commit
fileecho "Creating commit.."
GITAPPEND commit -am "Synced ZIM at: $(date -R), via custom bash script!"

get_github_remote

# pull from github repo, if requested
[ "$KEYWORD" == "pull-remote" ] && {
    fileecho "Pulling changes from Github Repository.."
    GITAPPEND pull $GH_REMOTE master
}

# push to github repo | if 'forced', push forcefully
fileecho "Pushing to Github repository.."
GITAPPEND push -u $GH_REMOTE master || {
    EXITSTATUS="$?"; 
    [ "$KEYWORD" == "forced-push" ] && {
        GITAPPEND push -uf $GH_REMOTE master
        EXITSTATUS="$?"
    }
    (( $EXITSTATUS )) && showerror "Pushing to Github repository failed!"
}
showinfo "Sync Complete."
exit 0
