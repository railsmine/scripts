#!/bin/bash
# =========================================================================================================================== #
# Only modify the code below, if you want to adjust the script behaviour somehow (e.g. to adjust with other app installations)
# =========================================================================================================================== #

function read-user-input {
    read response
    if [ "x$response" != x"" ]; then
        eval $1=$response
    else
        eval $1=$2
    fi
}

clear
if [ "$1" == "uninstall" ]; then
    echo "Uninstall $APPNAME from which directory? [e.g. $HOME/workspace/$APPNAME]"
    read-user-input UNINSTALLDIR ""
    if [ "x$UNINSTALLDIR" == x"" ]; then
        echo "please, provide a valid directory.. exiting.."
        exit
    fi
    echo "Delete Gemset: $APPNAME from RVM? [yes/no | Default: no]"
    read-user-input response no
    if [ "$response" == "yes" ]; then
        rvm use $RVM_RUBY_NAME
        rvm gemset delete $APPNAME
    fi
    echo "Which database this $APPNAME instance was using? [ if you provide a database name, I WILL DELETE THAT DATABASE! Press enter to Skip.. ]"
    read-user-input DELETEDATABASE ""
    if [ "x$DELETEDATABASE" != x"" ]; then
        echo "Are you sure, you want to drop database: $DELETEDATABASE ?? [yes/no | Default: no]"
        read-user-input response no
        if [ "$response" == "yes" ]; then
            QUERY="drop database $DELETEDATABASE"
            mysql -u$MYSQL_ROOTUSER -p$MYSQL_ROOTPASS -e "$QUERY"
            if [ $? != 0 ]; then
                echo "Could not delete database for some reasons.."
            fi
        fi
    fi
    echo "Delete $APPNAME Directory i.e. $UNINSTALLDIR ?? [yes/no | Default: no]"
    read-user-input response no
    if [ "$response" == "yes" ]; then
        echo "Are you sure, you want to delete directory: $UNINSTALLDIR (make sure this is an absolute path) ?? [yes/no | Default: no]"
        read-user-input response no
        if [ "$response" == "yes" ]; then
            rm -rf $UNINSTALLDIR
        fi
    fi
    
    sudo /etc/init.d/$APPNAME-passenger stop
    
    if [ -f /etc/init.d/$APPNAME-passenger ]; then
        sudo rm /etc/init.d/$APPNAME-passenger
    fi
    
    echo
    echo "Uninstalled $APPNAME!"
    echo "Remember to kill Passenger Daemon running for this Instance.."
    echo
    echo "Completed."
    exit
fi
if [ "$1" == "defaults" ]; then
    INSTALLDIR=$HOME/workspace
else
    if [ "$2" == "." ]; then
        echo "Installing $APPNAME in Current Directory.."
        INSTALLDIR=`pwd`
    else
        echo "Where should I install $APPNAME ($APPNAME will be installed inside this directory)? [Default: $HOME/workspace]"
        read response
        if [ "x$response" != x"" ]; then
            if [ ! -d $response ]; then
                echo "Directory: $response does not exist. Should I create it? [yes/no]"
                read response2
                if [ "$response2" == "yes" ]; then
                    mkdir -p $response2
                else
                    exit
                fi
            fi
            INSTALLDIR=$response
        else
            INSTALLDIR=$HOME/workspace
        fi
    fi
fi
cd $INSTALLDIR

# fetch or update via subversion
if [ -d "$APPNAME" ]; then
	echo "Updating $APPNAME Source..."
	update-source
else
	echo "Downloading $APPNAME Source..."
	download-source
fi

echo
echo "Try to attach this $APPNAME instance with Phusion passenger (passenger should be already configured!)? [yes/no | Default: yes]"
read-user-input USE_PASSENGER yes
if [ "$USE_PASSENGER" == "yes" ]; then
    if [ "$1" == "defaults" ]; then
        APPDOMAIN=$APPNAME.local
    else
        echo "What is the domain name where this $APPNAME instance will be used? [Default: $APPNAME.local]"
        read-user-input APPDOMAIN $APPNAME.local
    fi
else
    echo "Since, you are not using Passenger, Apache configurations will not be touched!"
fi
if [ "$1" == "defaults" ]; then
    MYSQL_DATABASE=$APPNAME
    MYSQL_USERNAME=$APPNAME
    MYSQL_PASSWORD=password
else
    # create MySQL database and user.
    echo "Creating MySQL user and password for $APPNAME"
    echo "Which Database should be used (or created) for this $APPNAME Instance? [Default: $APPNAME]"
    read-user-input MYSQL_DATABASE $APPNAME

    echo "Which Database user should be created for this $APPNAME Instance? [Default: $APPNAME]"
    read-user-input MYSQL_USERNAME $APPNAME

    echo "And, what should the password be for this database user? [Default: password]"
    read-user-input MYSQL_PASSWORD password
fi
QUERY="create database if not exists $MYSQL_DATABASE character set utf8;"
mysql -u$MYSQL_ROOTUSER -p$MYSQL_ROOTPASS -e "$QUERY"
if [ $? != 0 ]; then
    echo "Could not create database.. Exiting.."
    exit
fi
QUERY="create user '$MYSQL_USERNAME'@'$MYSQL_HOSTNAME' identified by '$MYSQL_PASSWORD';"
mysql -u$MYSQL_ROOTUSER -p$MYSQL_ROOTPASS -e "$QUERY" 2>/dev/null

QUERY="grant all privileges on $MYSQL_DATABASE.* to '$MYSQL_USERNAME'@'$MYSQL_HOSTNAME';"
mysql -u$MYSQL_ROOTUSER -p$MYSQL_ROOTPASS -e "$QUERY"
if [ $? != 0 ]; then
    echo "Could not grant access to database user on database.. Exiting.."
    exit
fi

if [ ! -f config/database.yml ]; then
    echo -e "production:
  adapter: mysql
  database: $MYSQL_DATABASE
  host: $MYSQL_HOSTNAME
  username: $MYSQL_USERNAME
  password: $MYSQL_PASSWORD
  encoding: utf8" > config/database.yml
fi

echo 
echo "We have created Database Configuration for you, based on the information provided by you (or, using the defaults)."
if [ "$1" != "defaults" ]; then
    echo "You can edit it as required on the next screen.."
    read -p "Press any key to edit database.yml [ENTER]"

    nano config/database.yml
fi
custom-file-changes $1

echo
echo "Running RVM related commands.."
source $HOME/.rvm/scripts/rvm
echo "Creating .rvmrc for this $APPNAME instance.."
rvm use $RVM_RUBY_NAME@$APPNAME --create --rvmrc
echo "Installing Bundler, since we will be using Gemfile.."
gem install bundler --no-ri --no-rdoc
generate-gem-file
echo "Gemfile created.."
echo "Running Bundler.."
bundle install
echo
rake-process


clear
echo
echo
echo "==================================================================================================="
echo "$APPNAME WAS INSTALLED!"
echo "Now, wait for a second or two, to let Webrick boot up this $APPNAME instance.."
if [ "$USE_PASSENGER" == "yes" ]; then
    echo "Open http://localhost:4096/ to check if $APPNAME is working fine...!"    
    echo "We need to ensure that the install was successful, before we make this work with Passenger.."
    echo "Use CTRL+C to kill the server and proceed with install.."
else
    echo "Open http://0.0.0.0:4096/ to see this working.."
    echo -e "You can always use:\n\`cd $INSTALLDIR/$APPNAME && ruby script/server webrick -e production -p 4096 -d\`\nto re-run this $APPNAME server as a daemon, or add this to your startup scripts."
fi
echo "=================================================================================================="
echo 
if [ "$USE_PASSENGER" == "yes" ]; then
    ruby script/server webrick -e production -p 4096
else
    ruby script/server webrick -e production -p 4096 -d
fi
echo
echo
echo -e "\tCompleted."
echo 

if [ "$USE_PASSENGER" == "yes" ]; then
    clear
    echo
    if [ "$1" == "defaults" ]; then
        response="yes"
    else
        echo "Let us know, if $APPNAME was found at: http://localhost:4096/ [yes/no]"
        read response
    fi
    echo
    if [ "$response" == "yes" ]; then
        echo "Now, we will configure Passenger to work with $APPNAME.."
        echo
        echo "Assuming, Passenger has been configured for rails already.."
        echo
        cp $SCRIPTDIR/files/passenger/passenger_setup_load_paths.rb config/setup_load_paths.rb
        if [ "$1" != "defaults" ]; then
            echo "Are you using Passenger with mod_proxy (standalone passenger)? [yes/no]"
            read response
        fi
        if [ "$response" == "yes" ]; then
            if [ "$1" == "defaults" ]; then
                PASSENGER_PORT=$DEFAULT_PORT
            else
                echo "Which port should I install this Passenger standalone instance on (make sure no other process is using this port)? [Default: 3001]"
                read-user-input PASSENGER_PORT $DEFAULT_PORT
            fi
            echo "Starting Passenger on Port: $PASSENGER_PORT"
            APP_DIRECTORY=$INSTALLDIR/$APPNAME/public
            sudo bash -c "sed -e 's|app-name|$APPNAME|g' -e 's|app-port|$PASSENGER_PORT|g' $SCRIPTDIR/files/passenger/passenger-init-script > /etc/init.d/$APPNAME-passenger"
            echo "Created a init service for passenger for $APPNAME. You can use, e.g. \`/etc/init.d/$APPNAME-passenger stop\` to stop this passenger instance. (do not use sudo)"
            sudo bash -c "sed -e 's|app-domain|$APPDOMAIN|g' -e 's|app-dir|$APP_DIRECTORY|g' -e 's|app-port|$PASSENGER_PORT|g' $SCRIPTDIR/files/passenger/passenger-local > /etc/apache2/sites-available/$APPDOMAIN"
            echo "Generated apache configuration directives and saved them in /etc/apache2/sites-available/.."
            sudo a2ensite $APPDOMAIN
            sudo /etc/init.d/apache2 reload
            sudo chmod 755 /etc/init.d/$APPNAME-passenger
            echo
            /etc/init.d/$APPNAME-passenger start
            #sudo update-rc.d redmine-passenger defaults 98
        else
            sudo bash -c "echo -e '<VirtualHost *:80>\nServerName $APPNAME.local\nDocumentRoot $INSTALLDIR/$APPNAME/public\n</VirtualHost>' > /etc/apache2/sites-available/$APPDOMAIN"
            echo "Generated apache configuration directives and saved them in /etc/apache2/sites-available/.."
            sudo a2ensite $APPDOMAIN
            sudo /etc/init.d/apache2 reload
        fi
    else
        echo "Sorry, but I have no option other than leaving you hanging here. :("
        echo
        exit
    fi
    echo "# ======================================================================================================= #"
    echo "$APPNAME has been installed with Passenger Support.."
    echo "Open: http://$APPDOMAIN/ to see it working (but do update your /etc/hosts, if this is a local install).."
    echo "# ======================================================================================================= #"
    
    echo
    echo -e "\tCompleted."
    echo
fi
