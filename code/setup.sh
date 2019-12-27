#!/bin/bash

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
# This script is part of the homebridge-cbus-installer:
# https://github.com/greiginsydney/homebridge-cbus-installer
#
# Original code thanks to Daryl McDougall


set -e # The -e switch will cause the script to exit should any command return a non-zero value

# keep track of the last executed command
# https://intoli.com/blog/exit-on-errors-in-bash-scripts/
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\"" command failed with exit code $?.' EXIT

#Shell note for n00bs like me: in Shell scripting, 0 is success and true. Anything else is shades of false/fail.


# -----------------------------------
# START FUNCTIONS
# -----------------------------------


step1 ()
{
	curl -sl https://deb.nodesource.com/setup_10.x | sudo -E bash -
	apt-get install -y nodejs
	apt-get install -y libavahi-compat-libdnssd-dev
	npm install -g --unsafe-perm homebridge
	npm install -g homebridge-cbus
	echo ""
	echo ">> download and setup java:"
	apt-get install openjdk-8-jre-headless -y
	echo ""
	echo ">> download and setup c-gate:"
	wget https://updates.clipsal.com/clipsalsoftwaredownload/mainsite/cis/technical/cgate/cgate-2.11.4_3251.zip
	unzip cgate-2.11.4_3251.zip
	mv cgate /usr/local/bin
	echo ""
	echo ">> Set CGate to start as a service using systemd"
	[ -f cgate.service ] && mv -fv cgate.service /etc/systemd/system/
	systemctl enable cgate.service
	systemctl start cgate.service
	echo ""
	echo ""
	echo "======================================="
	echo "C-Gate won't let remote clients connect to it if they're not in the file"
	echo "/usr/local/bin/cgate/config/access.txt."
	echo "Add your Admin machine's IP address here, or to whitelist an entire network"
	echo "add it with '255' as the last octet. e.g.:"
	echo "192.168.1.7 whitelists just the one machine, whereas"
	echo "192.168.1.255 whitelists the whole 192.168.1.x network."
	echo "The more IPs you whitelist, the less secure C-Gate becomes."
	echo ""
	whitelistMe=$(hostname -I) #This gets the PI's current IP address
	whitelistMe=$(awk -F"." '{print $1"."$2"."$3".255"}'<<<$whitelistMe) #This changes the last octet to 255
	read -e -i "$whitelistMe" -p  "Enter an IP or network address to allow/whitelist : " whitelistMe
	if [ ! -z "$whitelistMe" ];
	then 
		sed -i "/^## End of access control file/i interface $whitelistMe Program" /usr/local/bin/cgate/config/access.txt
	fi
	echo "======================================="
	echo ""
	# Prepare for reboot/restart:
	echo ">> Exited step 1 OK. A reboot is required to kick-start C-Gate and prepare for Step 2."
}

step2 ()
{
	cd  ${HOME}
	projectName=$(find -maxdepth 1 -type f -iname "*.xml")
	if [ ! -z "$projectName" ];
	then
		filename=$(basename -- "$projectName")
		filename="${filename%.*}"
		echo ">> Assuming project name = $filename, and setting C-Gate project.start & project.default values accordingly."
		[ -f *.xml ] && mv *.xml /usr/local/bin/cgate/tag/ # mv xxxxx.xml /usr/local/bin/cgate/tag
		sed -i -E "s/^project.default=(.*)/project.default=$filename/" /usr/local/bin/cgate/config/C-GateConfig.txt
		sed -i -E "s/^project.start=(.*)/project.start=$filename/" /usr/local/bin/cgate/config/C-GateConfig.txt
		sed -i -E "s/^(.*)HOME(.*)/\1$filename\2/" config.json
		[ -f homebridge ] && mv -fv homebridge /etc/default/
		[ -f homebridge.service ] && mv -fv homebridge.service /etc/systemd/system/
		[ -f homebridge.timer ] && mv -fv homebridge.timer /etc/systemd/system/
		id -u homebridge &>/dev/null || useradd -M --system homebridge
		mkdir -pv /var/lib/homebridge
		chown -R homebridge:homebridge /var/lib/homebridge
		chmod 777 -R /var/lib/homebridge
		[ -f config.json ] && mv -fv config.json /var/lib/homebridge/
		touch my-platform.json
		chown -R homebridge:homebridge /home/pi/my-platform.json
		chmod 777 -R /home/pi/my-platform.json
		systemctl daemon-reload
		systemctl enable homebridge.timer
		systemctl start homebridge.timer
	else
		echo ""
		echo ">> No Tags file found. Please upload it to /home/pi/ and re-run Step2"
		echo ""
		exit
	fi
	
	echo ">> Exited step 2 OK."
}


test_install ()
{
	echo "TEST!"
}


prompt_for_reboot()
{
	echo ""
	read -p "Reboot now? [Y/n]: " rebootResponse
	case $rebootResponse in
		(y|Y|"")
			echo "Bye!"
			exec reboot now
			;;
		(*)
			return
			;;
	esac
}


# -----------------------------------
# END FUNCTIONS
# -----------------------------------


# -----------------------------------
# THE FUN STARTS HERE
# -----------------------------------


if [ "$EUID" -ne 0 ];
then
	echo -e "\nPlease re-run as 'sudo ./Setup.sh <step>'"
	exit 1
fi

case "$1" in
	("step1")
		step1
		prompt_for_reboot
		;;
	("step2")
		step2
		prompt_for_reboot
		;;
	("test")
		test_install
		prompt_for_reboot
		;;
	("")
		echo -e "\nNo option specified. Re-run with 'step1', 'step2', or 'test' after the script name\n"
		exit 1
		;;
	(*)
		echo -e "\nThe switch '$1' is invalid. Try again.\n"
		exit 1
		;;
esac

# Exit from the script with success (0)
exit 0
