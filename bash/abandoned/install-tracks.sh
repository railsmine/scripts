#!/bin/bash

# ============================================================================================================================== #
# This script installs a tracks instance, assuming rvm is installed with proper support. Also, generate some code for Passenger
# This script requires RVM (currently, user-based-installs) along with a Ruby 1.8.7 install (see web-dev-install.sh)
# run with `./install-tracks.sh uninstall` to uninstall tracks from a directory
# run with `./install-tracks.sh defaults` to run installer with default parameters
# add a second parameter as dot ".", if you want to install tracks in current directory itself, else you will be asked.
# e.g. ./install-tracks.sh defaults .
# or ./install-tracks.sh .
# TODO: Make webrick boot on an available port, rather than a fixed port (4096 here), which can not be free at times. (`lsof -i :4096`)
# ============================================================================================================================== #


RVM_RUBY_NAME=1.8.7             # RVM ruby name (must be ruby version 1.8.6 or 1.8.7)

MYSQL_ROOTUSER=root             # Your MySQL root username and password
MYSQL_ROOTPASS=password         
MYSQL_HOSTNAME=localhost        # MySQL Hostname

SCRIPTDIR=$HOME/Documents/bash-scripts  # Directory where this script is saved.
DEFAULT_PORT=3002

# =========================================================================================================================== #
# ONLY Change these variables/functions, if you are trying to modify this script for some other installation.
# You may still need to change the script further down, but this will just help you make it more easier.
# =========================================================================================================================== #

APPNAME=tracks


function update-source {
	# how should the downloaded app-instance be updated?
	cd $INSTALLDIR/$APPNAME
	git pull origin
}
function download-source {
    # how can I download this app-instance?
    DOWNLOAD_URL=git://github.com/bsag/tracks.git
	git clone $DOWNLOAD_URL $APPNAME
	cd $INSTALLDIR/$APPNAME
}
function custom-file-changes {
    # if you want to modify, files other than database.yml enter your commands here.
    # database.yml is auto-generated, and these steps will take place after that edit..
    if  [ "$1" != "defaults" ]; then
        if [ ! -f $INSTALLDIR/$APPNAME/config/site.yml ]; then
            cp $INSTALLDIR/$APPNAME/config/site.yml.tmpl $INSTALLDIR/$APPNAME/config/site.yml
        fi
        echo "$APPNAME requires some further configuration settings."
        read -p "Press a key to edit site.yml [ENTER]"
        nano $INSTALLDIR/$APPNAME/config/site.yml
    fi
    echo "All custom configurations has been saved, if any."
}
function generate-gem-file {
    # place here the content of a Gemfile that can be used to generate the gems this app requires.
    cp $SCRIPTDIR/files/$APPNAME/Gemfile $INSTALLDIR/$APPNAME/Gemfile
}
function rake-process {
    # once all the file-edits are done and Gems have been installed, we need to rake our app-instance
    # place here all the rake instance and also, any other changes/commands you need to ensure.
    RAILS_ENV=production rake gems:install
    echo "Migrating database, if needed.."
    RAILS_ENV=production rake db:migrate
}

# =========================================================================================================================== #
# Omitting repeated use of the same code, and added it to a standalone (but pretty unsusable) shell script..
# =========================================================================================================================== #

. $SCRIPTDIR/install-base.sh
