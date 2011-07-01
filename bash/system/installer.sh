#!/bin/bash
#
# Install softwares, while displaying the package details
#
set -o errexit

[ "$1" == "-q" ] || { echo -e "===============================================================\nRunning:      Software Installer\nOn Time:      `date -R`\n===============================================================\n"; shift; }

function script_failure() { echo -e "\n================================\nFAILURE `date -R`"; exit 1; }

echo -e "Getting Software Details..\n================================"
apt-cache show "$@" || { echo "Could not update apt repositories."; script_failure; }

echo -e "Installing required packages....\n================================"

for i in "$@"; do
	echo -e "\n\n"
	sudo apt-get -fyuV install $i || { echo -e "================================\nCould not install package: $i"; script_failure; }
done

echo -e "\n================================\n\nSUCCESS"
