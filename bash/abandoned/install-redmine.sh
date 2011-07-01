#!/bin/bash

# ============================================================================================================================== #
# This script installs a redmine instance, assuming rvm is installed with proper support. Also, generate some code for Passenger
# This script requires RVM (currently, user-based-installs) along with a Ruby 1.8.7 install (see web-dev-install.sh)
# run with `./install-redmine.sh uninstall` to uninstall redmine from a directory
# run with `./install-redmine.sh defaults` to run installer with default parameters
# add a second parameter as dot ".", if you want to install redmine in current directory itself, else you will be asked.
# e.g. ./install-redmine.sh defaults .
# or ./install-redmine.sh .
# TODO: Make webrick boot on an available port, rather than a fixed port (4096 here), which can not be free at times. (`lsof -i :4096`)
# TODO: If redmine is updated to another version, due to version numbers in svn url, it will not auto-upgrade to newer version, at the moment.
# FIXME: passenger is not auto-started on reboot.. rvm environment mismatch between rvm user and root..
# ============================================================================================================================== #

RVM_RUBY_NAME=1.8.7             # RVM ruby name (must be ruby version 1.8.6 or 1.8.7)

MYSQL_ROOTUSER=root             # Your MySQL root username and password
MYSQL_ROOTPASS=password         
MYSQL_HOSTNAME=localhost        # MySQL Hostname

SCRIPTDIR=$HOME/Documents/bash-scripts  # Directory where this script is saved.
DEFAULT_PORT=3001

# =========================================================================================================================== #
# ONLY Change these variables/functions, if you are trying to modify this script for some other installation.
# You may still need to change the script further down, but this will just help you make it more easier.
# =========================================================================================================================== #

APPNAME=redmine
LATEST_VERSION=1.1.2

function update-source {
	# how should the downloaded app-instance be updated?
	cd $INSTALLDIR/$APPNAME
	svn update
}
function download-source {
    # how can I download this app-instance?
    DOWNLOAD_URL=http://redmine.rubyforge.org/svn/tags/$LATEST_VERSION/
	svn co $DOWNLOAD_URL $APPNAME
	cd $INSTALLDIR/$APPNAME
}
function custom-file-changes {
    # if you want to modify, files other than database.yml enter your commands here.
    # database.yml is auto-generated, and these steps will take place after that edit..
    echo "All custom configurations have been saved, if any."
}
function generate-gem-file {
    # place here the content of a Gemfile that can be used to generate the gems this app requires.
    cp $SCRIPTDIR/files/$APPNAME/Gemfile $INSTALLDIR/$APPNAME/Gemfile
}
function rake-process {
    # once all the file-edits are done and Gems have been installed, we need to rake our app-instance
    # place here all the rake instance and also, any other changes/commands you need to ensure.
    echo "Generating Session Key for this redmine instance.."
    rake generate_session_store
    echo "Migrating database, if needed.."
    RAILS_ENV=production rake db:migrate
    echo "Loading default configuration data.."
    RAILS_ENV=production rake redmine:load_default_data

    echo "Now, doing some checks.. do not worry, if these fail.."
    mkdir tmp public/plugin_assets
    sudo chown -R $USER:$USER files log tmp public/plugin_assets
    sudo chmod -R 755 files log tmp public/plugin_assets
}

# =========================================================================================================================== #
# Omitting repeated use of the same code, and added it to a standalone (but pretty unsusable) shell script..
# =========================================================================================================================== #

. $SCRIPTDIR/install-base.sh
