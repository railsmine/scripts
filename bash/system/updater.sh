#!/bin/bash
#
# Upgrade Ubuntu, Remove old files and cleanup.
#
set -o errexit

if [ "$1" != "-q" ]; then
echo "===============================================================
Running:      System Updater
On Time:      `date -R`
===============================================================
";
fi

function script_failure() {
	echo
	echo "================================"
	echo
	echo "FAILURE `date -R`";
	exit 1;
}

echo "Updating Cache.."
echo "================================"
sudo apt-get update || { echo "Could not update apt repositories."; script_failure; }
echo
echo "Running System Upgrade.."
echo "================================"
sudo apt-get -fyuV upgrade || { echo "System Upgrade Failed."; script_failure; }
echo
echo "Running Distribution Upgrade...."
echo "================================"
sudo apt-get -fyuV dist-upgrade || { echo "Distribution Upgrade Failed."; script_failure; }
echo
echo "Removing unnecessary packages..."
echo "================================"
sudo apt-get -fyuV autoremove || { echo "Failed to automatically remove unnecessary packages."; script_failure; }
echo
echo "Removing old cached downloads..."
echo "================================"
sudo apt-get -fyuV autoclean || { echo "Failed to cleanup old downloads."; script_failure; }
echo
echo "================================"
echo
echo "SUCCESS"
