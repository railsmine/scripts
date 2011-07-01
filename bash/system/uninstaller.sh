#!/bin/bash
#
# Uninstall packages..
#
set -o errexit

if [ "$1" != "-q" ]; then
echo "===============================================================
Running:      Software Uninstaller
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

echo "Uninstalling softwares.."
echo "================================"
for i in "$@"; do
	echo
	echo
	sudo apt-get -fyuV remove $i || { echo; echo "================================";echo; echo "Could not remove package: $i"; script_failure; }
done
echo
echo "Uninstalling unnecessary packages.."
echo "================================"
sudo apt-get -fyuV autoremove || { echo; echo "================================";echo; echo "Could not automatically remove unnecessary packages.."; script_failure; }

echo
echo "================================"
echo
echo "SUCCESS"
