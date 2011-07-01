#!/bin/bash
# Initializes Git, sets up a gitolite server, syncs with Github, and so on.. ;)

GITOLITE_ADMIN_DIR=/home/$USERNAME/workspace/gitolite-admin
GITOLITE_CONF=$GITOLITE_ADMIN_DIR/conf/gitolite.conf
GITSERVER=gitserver
SSHSTRING="ssh root@vps"
PATHTOREPOS="/home/develop/repositories"
GITHUB_USER=$USERNAME
GITHUB_TOKEN="<GITHUBTOKEN>"
#REMOTENAMES="origin gitolite" # $GITSERVER is always added as a REMOTENAME

function oneline_usage() {
    echo $"Usage: init-gitolite.sh [-ghdvV0] [-r repo_macro] [dirname] [reponame]"
    exit 999
}
function version() {
    echo -e $"Gitolite init script\nVersion 1.1\nby Nikhil Gupta\n[me@nikhgupta.com]"
    exit 999
}

function error { show_success 0 "failed" "$1"; }
function warn { show_success 1 "warning" "$1"; }
function success { show_success 2 "success" "$1"; }
function die { show_success 3 "aborted" "$1"; exit 999; }

function show_success() {
	# Parameters: condition_check (0|1|2|3), warn|fail|success|abort, [desc]
	# Parameters: condition_check (0|1|2|3), message, [desc]
	message=( $(echo "$2" | tr '|' ' ') ); message="${message[$1]}"; message=${message:-"$2"}
    color=( "${RED}" "${YLW}" "${GRN}" "${RED}" )
    desc=( "_Error_" "Warning" "Success" "ABORTED")
    if (( $COLORCODES )); then desc="${color[$1]}${desc[$1]}!${NML} $3" ; else desc="${desc[$1]}! $3"; fi
    [ -n "$3" ] && echo -ne "${desc}";
    if (( $COLORCODES )); then tput hpa $COL; echo -e "${color[$1]}[ ${message} ]${NML}";
    else printf "\n%${COL}s\n" "...[ ${message} ]"; fi
}
function check_requirements() {
    type -P sed  &>/dev/null || die "I require 'sed'  but it's not installed."
    type -P grep &>/dev/null || die "I require 'grep' but it's not installed."
    type -P tput &>/dev/null || die "I require 'tput' but it's not installed."
    type -P git  &>/dev/null || die "I require 'git'  but it's not installed."
    # check if the gitolite-admin directory is actually present
    [ -w "$GITOLITE_CONF" ] || die "can not read/write gitolite configuration file.."
    # check if a git repository already exists for this repo
    [ -d "$REPO_DIR/.git" ] && die "a git repository already exists for this location!"
}
function GIT() {
    GIT_DIR="$1"; shift;
    SUCCESS="$1"; shift;
    FAILURE="$1"; shift;
    GIT="git --git-dir=${GIT_DIR}/.git --work-tree=${GIT_DIR}"
    if (( $VERBOSE )) || [ "$SUCCESS" == "NIL" ]; then
        if $GIT "$@"; then
            [ "$SUCCESS" != "NIL" ] && success "$SUCCESS";
        else
            [ "$FAILURE" != "NIL" ] && die "$FAILURE";
        fi
    else
        if $GIT "$@" 1>/dev/null; then
            [ "$SUCCESS" != "NIL" ] && success "$SUCCESS";
        else
            [ "$FAILURE" != "NIL" ] && die "$FAILURE";
        fi
    fi
}
function delete_repo() {
    REPO_NAME="`GIT "$REPO_DIR" "NIL" "NIL" remote -v show | grep "gitserver:" | head -1 | cut -f2 | cut -f1 -d' ' | cut -f2 -d':' | cut -f1 -d'.'`"
    [ -n "$REPO_NAME" ] || die "Could not extract remote repository name..."
    sed -e "s|${REPO_NAME} ||g" -i $GITOLITE_CONF && success "made changes to gitolite configuration file.."
    rm -rf $REPO_DIR/.git/ && success "removed local git repository.."
    $SSHSTRING "rm -rf $PATHTOREPOS/$REPO_NAME.git" && success "removed gitolite server repository for this repository.."
    (( $GITHUB_REPO )) && token=$(curl -X POST -su "$GITHUB_USER/token:$GITHUB_TOKEN" http://github.com/api/v2/json/repos/delete/$GITHUB_USER/"$REPO_NAME" | cut -f4 -d'"')
	curl -d "delete_token=${token}" -su "$GITHUB_USER/token:$GITHUB_TOKEN" http://github.com/api/v2/json/repos/delete/$GITHUB_USER/"$REPO_NAME" &>/dev/null && success "Removed Github repository at: http://github.com/$GITHUB_USER/$REPO_NAME"
}

while getopts ":dgvV0r:" options
do
  case $options in
    d) DELETE_REPO=1;;
    g) GITHUB_REPO=1;;
    v) VERBOSE=1;;
    0) COLORCODES=0;;
    r) REPO_MACRO="$OPTARGS";;
    V) version;;
    h) oneline_usage;;
    *) oneline_usage;;
  esac
done
shift $(($OPTIND - 1))

DELETE_REPO=${DELETE_REPO:-0}
GITHUB_REPO=${GITHUB_REPO:-0}
VERBOSE=${VERBOSE:-0}
SHORTUSAGE=${SHORTUSAGE:-0}
COLORCODES=${COLORCODES:-1}
(( $COLORCODES )) && BLD=$(tput bold)
(( $COLORCODES )) && NML=$(tput sgr0)
(( $COLORCODES )) && RED=$BLD$(tput setaf 1)
(( $COLORCODES )) && GRN=$BLD$(tput setaf 2)
(( $COLORCODES )) && YLW=$BLD$(tput setaf 3)
(( $COLORCODES )) && BLU=$BLD$(tput setaf 6)
COL=$(tput cols); let COL=COL-16

# check back which repo macro is the one, the user wants to add the repository in
case $REPO_MACRO in
    pr) REPO_MACRO="public-readable";;
    pw) REPO_MACRO="public-writable";;
    nr) REPO_MACRO="nikhgupta-repos";;
    cw) REPO_MACRO="client-works";;
    64) REPO_MACRO="inpiron-1564-repos";;
esac
REPO_MACRO=${REPO_MACRO:-"inspiron-1564-repos"}

# if no directory is given create git repository in current directory
REPO_DIR=${1:-"$(pwd)"}
# if no name is given, create name based on directory name
REPO_NAME="${REPO_DIR##*/}"
REPO_NAME="${2:-$REPO_NAME}"

# delete git repository if requested
(( $DELETE_REPO )) && { delete_repo; exit 900; }

# check our requirements
check_requirements

# Pull changes from Gitolite server
GIT "$GITOLITE_ADMIN_DIR" "fetched changes from gitolite server.." "cannot fetch changes from Gitolite server.." fetch -v origin master

# backup our existing Gitolite Configuration file
cp $GITOLITE_CONF $GITOLITE_CONF.bak && success "backed up existing gitolite configuration file.."

# make changes to our Gitolite Configuration file, if needed.
sed -e 's/\(@'"$REPO_MACRO"'.*\) #/\1 '"$REPO_NAME"' #/g' -i $GITOLITE_CONF && success "made changes to gitolite configuration file.."

GIT "$GITOLITE_ADMIN_DIR" "Added untracked files in 'gitolite-admin' repo" "Failed to add untracked files in 'gitolite-admin' repository" add .
GIT "$GITOLITE_ADMIN_DIR" "Added a new commit for this Gitolite change" "Failed to make a commit for this Gitolite change" commit -am "Added repo: $REPO_NAME"
GIT "$GITOLITE_ADMIN_DIR" "Pushed 'gitolite-admin' repository to Gitolite server" "Failed to push 'gitolite-admin' repository to Gitolite server" push origin master
if ssh $GITSERVER 2>/dev/null | tail -n +3 | cut -f2 | grep -q "$REPO_NAME"; then success "Created a new bare repository on Gitolite server";
else die "Failed to find a reference of the new repository on Gitolite server"; fi

GIT "$REPO_DIR" "Initialized new repository in '${REPO_DIR}'" "Failed to initilialize new repository in '${REPO_DIR}'" init
GIT "$REPO_DIR" "Added untracked files in repository for tracking" "Failed to add untracked files in repository" add .
GIT "$REPO_DIR" "Made the first commit with Gitolite server" "Failed to make the first commit" commit -am "First Sync with Gitolite Server"

#for REMOTE in $REMOTENAMES ; do
#    GIT "$REPO_DIR" "Added remote branch with name: $REMOTE" "Failed to add a remote branch" remote add $REMOTE $GITSERVER:$REPO_NAME.git
#done
GIT "$REPO_DIR" "Added remote branch with name: gitserver" "Failed to add a remote branch" remote add $GITSERVER $GITSERVER:$REPO_NAME.git

GIT "$REPO_DIR" "Pushed the new repository to Gitolite server" "Failed to push the new repository to Gitolite server" push $GITSERVER --all

if (( $GITHUB_REPO )); then
	curl -d "name=$REPO_NAME" -su "${GITHUB_USER}/token:${GITHUB_TOKEN}" http://github.com/api/v2/json/repos/create &>/dev/null && success "created a github repository at: http://github.com/$GITHUB_USER/$REPO_NAME"
	GIT "$REPO_DIR" "Added Remote branch with name: Github" "Failed to add a remote branch for Github" remote add github git@github.com:$GITHUB_USER/$REPO_NAME.git
	GIT "$REPO_DIR" "Pushed the new repository to Github server" "Failed to push the new repository to Github server" push github --all
fi

touch $REPO_DIR/.git/$TRACK_FILE && success "Created .git/$TRACK_FILE file for preventing re-run of this script"
success "INITIALIZED LOCAL REPO AND SYNCED WITH GITOLITE REPO!!"
echo "--------------------------------------------"
echo "git clone $GITSERVER:$REPO_NAME"
if [ "$3" == "github" ]; then
    echo "git clone $GITHUB_REPO"
fi
echo "--------------------------------------------"
echo -e "\t${BLU}Completed${NML}."
