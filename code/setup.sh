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
trap 'echo "\"${last_command}\"" command failed with exit code $?.' ERR

#Shell note for n00bs like me: in Shell scripting, 0 is success and true. Anything else is shades of false/fail.


# -----------------------------------
# START FUNCTIONS
# -----------------------------------


step1 ()
{
	echo "======================================="
	echo ""
	echo ">> manually extract from the repo & tidy up"
 	[ -f "/home/${SUDO_USER}/Homebridge-cbus-installer/code/cgate.service" ] && mv -fv /home/${SUDO_USER}/Homebridge-cbus-installer/code/cgate.service /home/${SUDO_USER}
	[ -f "/home/${SUDO_USER}/Homebridge-cbus-installer/code/homebridge.timer" ] && mv -fv /home/${SUDO_USER}/Homebridge-cbus-installer/code/homebridge.timer /home/${SUDO_USER}
	rm -rf /home/${SUDO_USER}/Homebridge-cbus-installer
 	
  	echo "======================================="
	echo ""
	echo ">> download jq:"
	apt-get install jq
	echo "======================================="
	echo ""
	echo ">> setup java8:"
	archive=$(ls /home/${SUDO_USER}/jdk*.gz | head -n1)
	if [ ! $archive ];
	then
		echo ""
		echo "A jdk archive was not found in the user's home directory."
		echo "Review the install process (SETUP.md) and restart."
		echo ""
		exit
	else
		echo "Found ${archive[0]}"
	fi;

	rm -rf /usr/java
	mkdir /usr/java
	cd /usr/java
	tar -vxf "${archive[0]}"
	
	JVERSION=$(ls -d jdk* | head -n1) # Today that's "jdk1.8.0_381"

	update-alternatives --install /usr/bin/java  java  "/usr/java/${JVERSION[0]}/bin/java" 1000
	update-alternatives --install /usr/bin/javac javac "/usr/java/${JVERSION[0]}/bin/javac" 1000

 	echo ""
	java -version
 	echo ""
	javac -version
	echo "======================================="
	echo ""
	echo ">> c-gate:"
	if [ ! -d /usr/local/bin/cgate ];
	then
 		echo ">> download and setup c-gate:"
		wget https://updates.clipsal.com/clipsalsoftwaredownload/mainsite/cis/technical/cgate/cgate-2.11.4_3251.zip
		unzip cgate-2.11.4_3251.zip
		mv cgate /usr/local/bin
	else
		echo ""
		echo "/usr/local/bin/cgate exists. Download skipped"
	fi
	echo ""
	echo ">> Set CGate to start as a service using systemd"
	if [ -f /home/${SUDO_USER}/cgate.service ];
	then
		echo ">> Found cgate.service file in /home/${SUDO_USER}. Moving to /etc/systemd/system/"
		mv -fv /home/${SUDO_USER}/cgate.service /etc/systemd/system/
	else
		echo ">> Didn't find cgate.service file in /home/${SUDO_USER}. I hope it's already been moved to /etc/systemd/system/"
	fi
	systemctl enable cgate.service
	systemctl start cgate.service
	echo ""
	echo "======================================="
	echo ""
	echo "C-Gate won't let remote clients connect to it if they're not in the file"
	echo "/usr/local/bin/cgate/config/access.txt."
	echo "Add your Admin machine's IP address here, or to whitelist an entire network"
	echo "add it with '255' as the last octet. e.g.:"
	echo "  192.168.1.7 whitelists just the one machine, whereas"
	echo "  192.168.1.255 whitelists the whole 192.168.1.x network."
	echo "The more IPs you whitelist, the less secure C-Gate becomes."
	echo ""
	whitelistMe=$(hostname -I) #This gets the PI's current IP address
	whitelistMe=$(awk -F"." '{print $1"."$2"."$3".255"}'<<<$whitelistMe) #This changes the last octet to 255
	while [ 1 ];
	do
		read -e -i "$whitelistMe" -p  "Enter an IP or network address to allow/whitelist : " whitelistMe
		if [ ! -z "$whitelistMe" ];
		then 
			sed -i "/^## End of access control file/i interface $whitelistMe Program" /usr/local/bin/cgate/config/access.txt
			whitelistMe=""
		else
			break
		fi
	done
 	echo ">> end of step 1"
}

step2 ()
{
	# Step2 automatically follows Step1, but you can also manually jump here from the cmd line
	echo ">> start of step 2"
	#If you run Step2 with the -H switch (i.e. as root) it sets the path of /home/pi, otherwise follows the actual users $HOME env dir
	if [ "${HOME}" == "/root" ];
	then
		cd "/home/${SUDO_USER}/"
	fi
	if [ ! -f /usr/local/bin/cgate/config/C-GateConfig.txt ];
	then
		echo ""
		echo "ERROR: /usr/local/bin/cgate/config/C-GateConfig.txt does not exist."
		return
	fi
	projectName=$(find -maxdepth 1 -type f -iname "*.xml")
	if [ ! -z "$projectName" ];
	then
		filename=$(basename -- "$projectName")
		filename="${filename%.*}"
		echo ">> Assuming project name = $filename, and setting C-Gate project.start & project.default values accordingly."
		[ -f *.xml ] && mv *.xml /usr/local/bin/cgate/tag/ # mv xxxxx.xml /usr/local/bin/cgate/tag
		ln -snfv "/usr/local/bin/cgate/tag/${filename}.xml" "/usr/local/bin/cgate/tag\\$filename.xml"
		sed -i -E "s/^project.default=(.*)/project.default=$filename/" /usr/local/bin/cgate/config/C-GateConfig.txt
		sed -i -E "s/^project.start=(.*)/project.start=$filename/" /usr/local/bin/cgate/config/C-GateConfig.txt
		systemctl restart cgate.service

  		echo ">> homebridge timer:"
		if [ -f /home/${SUDO_USER}/homebridge.timer ];
		then
			echo ">> Found homebridge.timer file in /home/${SUDO_USER}. Moving to /etc/systemd/system/"
			mv -fv /home/${SUDO_USER}/homebridge.timer /etc/systemd/system/
		else
			echo ">> Didn't find homebridge.timer file in /home/${SUDO_USER}. I hope it's already been moved to /etc/systemd/system/"
		fi

		#Add the C-Gate settings to config.json - if they don't already exist:
		found=$(cat /var/lib/homebridge/config.json | jq ' .platforms | ( map(select(.name == "CBus")))')
		if [ "$found" == "[]" ];
		then
			# NB: jq can't edit in place, so we need to bounce through a .tmp file:
			cp /var/lib/homebridge/config.json /var/lib/homebridge/config.json.tmp &&
			cat /var/lib/homebridge/config.json.tmp | jq -r --arg SUDOUSER "${SUDO_USER}" '.platforms += [{ "platform": "homebridge-cbus.CBus", "name": "CBus", "client_ip_address": "127.0.0.1", "client_controlport": 20023, "client_cbusname": "HOME", "client_network": 254, "client_application": 56, "client_debug": true, "platform_export": "/home/\($SUDOUSER)/my-platform.json", "accessories": [] }]' > /var/lib/homebridge/config.json &&
			rm /var/lib/homebridge/config.json.tmp
			echo 'Added "homebridge-cbus.CBus" to /var/lib/homebridge/config.json OK'
		else
			echo 'Skipped: already in config.json'
		fi
		#Update the Project name:
		sed -i -E "s/^(.*)HOME(.*)/\1$filename\2/" /var/lib/homebridge/config.json
		touch my-platform.json
		chmod 777 -R /home/${SUDO_USER}/my-platform.json
		systemctl stop homebridge
		systemctl disable homebridge.service	#It runs under the control of the timer
		systemctl daemon-reload
		systemctl enable homebridge.timer
	else
		echo "======================================="
		echo ""
		echo "Copy your tags file (i.e. '<ProjectName>.xml)' to /home/${SUDO_USER}/ and then run Step2"
		echo "(If you don't know how to do this, I use WinSCP)"
		echo ""
		exit
	fi
	echo ">> Exited step 2 OK."
}


copy_groups ()
{
	# https://stackoverflow.com/questions/24998434/read-command-display-the-prompt-in-color-or-enable-interpretation-of-backslas
	# See "88/256 Colors": https://misc.flogisoft.com/bash/tip_colors_and_formatting
	GREEN="\033[38;5;10m"
	YELLOW="\033[38;5;11m"
	GREY="\033[38;5;60m"
	RESET="\033[0m"
	# This matches the format of the DISABLED accessories:
	matchRegex="^\S+(.*)(,\ \"enabled\":\ false.*)$"
	# Read a line from the file:
	# Thank you SO: https://stackoverflow.com/questions/6911520/read-command-in-bash-script-is-being-skipped
	#defaultChoice=""
	while read line <&9; do
		if [[ $line =~ $matchRegex ]] ;
		then
			thisGroup=${BASH_REMATCH[1]}
			echo ""
			echo $thisGroup
			
			#Skip if it's already in the file
			#Parse the json back to its constituents (for the search)
			thisType=$( echo "{$thisGroup}" | jq '. | .type ')
			thisNetwork=$( echo "{$thisGroup}" | jq '. | .network ')
			thisId=$( echo "{$thisGroup}" | jq '. | .id ')
			thisName=$( echo "{$thisGroup}" | jq '. | .name ')
			#Check if we need to specify the network in the search string
			if [ -z "$thisNetwork" ]; then
				found=$(cat /var/lib/homebridge/config.json | jq ' .. | objects | select(.accessories) | .accessories | if type == "array" then .[] else . end | select(.type == '"$thisType"' and .network == '"$thisNetwork"' and .id == '"$thisId"' and .name == '"$thisName"')')
			else
				found=$(cat /var/lib/homebridge/config.json | jq ' .. | objects | select(.accessories) | .accessories | if type == "array" then .[] else . end | select(.type == '"$thisType"' and .id == '"$thisId"' and .name == '"$thisName"')')
			fi
			if [ ! -z "$found" ]; then
				echo 'Skipped: already in config.json'
				#
				# TODO: Give the user the option to change the type
				#
				continue
			fi
			matchUnknown="\"type\":\ \"unknown\"(.+)"
			if [[ $thisGroup =~ $matchUnknown ]];
			then
				defaultChoice="c"
				read -p "$(echo -e ""$GREY"[a]dd,"$RESET" [s]kip, "$YELLOW"[C]hange & enable"$RESET", [q]uit? ")" choice
			else
				defaultChoice="a"
				read -p "$(echo -e ""$GREEN"[A]dd"$RESET", [s]kip, [C]hange & enable, [q]uit? ")" choice
			fi
			# Stuff in the appropriate default value if the user responded null:
			if [ -z "$choice" ];
			then
				case $defaultChoice in
					(a)
						choice="a"
						;;
					(c)
						choice="c"
						;;
				esac
			fi
			case $choice in
				(a|A)
					#
					# TODO: Neaten this. Invalidate A properly where type is Unknown
					#
					if [ "$defaultChoice" == "c" ] ;
					then
						echo "No you dont"
						continue
					else
						echo "Added"
					fi
					;;
				(s|S)
					echo "Skipped"
					continue #Jump to next Group
					;;
				(c|C)
					echo "Change to:"
					unset newType
					while [ -z $newType ];
					do
						read -p "[l]ight, s[w]itch, [d]immer, [f]an, [s]hutter, [m]otion, s[e]curity, [t]rigger, [c]ontact: " newType
						case $newType in 
							(l|L) replaceValue="light" ;;
							(w|W) replaceValue="switch" ;;
							(d|D) replaceValue="dimmer";;
							(f|F) replaceValue="fan";;
							(s|S) replaceValue="shutter";;
							(m|M) replaceValue="motion";;
							(e|E) replaceValue="security";;
							(t|T) replaceValue="trigger";;
							(c|C) replaceValue="contact";;
						esac
					done
					echo "Changed to $replaceValue"
					thisGroup="${thisGroup/unknown/$replaceValue}"
					;;
				(q|Q)
					break #We're outta here
					;;
			esac
			#Skip if a changed group type (e.g. from "Unknown") is already in the file:
			if [ "$defaultChoice" == "c" ] ;
			then
				#We can re-used the old parsed values for this fresh query, just updating the type:
				thisType="\"$replaceValue\""
				#Check if we need to specify the network in the search string
				if [ -z "$thisNetwork" ]; then
					found=$(cat /var/lib/homebridge/config.json | jq ' .. | objects | select(.accessories) | .accessories | if type == "array" then .[] else . end | select(.type == '"$thisType"' and .network == '"$thisNetwork"' and .id == '"$thisId"' and .name == '"$thisName"')')
				else
					found=$(cat /var/lib/homebridge/config.json | jq ' .. | objects | select(.accessories) | .accessories | if type == "array" then .[] else . end | select(.type == '"$thisType"' and .id == '"$thisId"' and .name == '"$thisName"')')
				fi
				if [ ! -z "$found" ]; then
					echo 'Skipped: already in config.json'
					continue
				fi
			fi
			
			cp /var/lib/homebridge/config.json /var/lib/homebridge/config.json.tmp &&
			cat /var/lib/homebridge/config.json.tmp | jq ' .platforms |= ( map(select(.name == "CBus").accessories += [{ '"$thisGroup"' }] ))' > /var/lib/homebridge/config.json &&
			rm /var/lib/homebridge/config.json.tmp
			
		fi
	done 9</home/${SUDO_USER}/my-platform.json
	echo "Done"
	matchRegex="^\S*\"pin\":\ \"(.+)\"$"
	while read line; do
		if [[ $line =~ $matchRegex ]];
		then
			thePin=${BASH_REMATCH[1]}
			break
		fi
	done </var/lib/homebridge/config.json
	echo ""
	echo "The PIN to enter in your iDevice is $thePin"
	echo ""
}


restart_homebridge ()
{
	read -p "Restart Homebridge? [Y/n]: " restartResponse
	case $restartResponse in
		(y|Y|"")
			systemctl restart homebridge
			;;
		(*)
			return
			;;
	esac
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
		step2
		prompt_for_reboot
		;;
	("step2")
		step2
		prompt_for_reboot
		;;
	("copy")
		copy_groups
		restart_homebridge
		;;
	("test")
		test_install
		prompt_for_reboot
		;;
	("")
		echo -e "\nNo option specified. Re-run with 'step1', 'step2', 'copy' or 'test' after the script name\n"
		exit 1
		;;
	(*)
		echo -e "\nThe switch '$1' is invalid. Valid options are 'step1', 'step2', 'copy' and 'test'.\n"
		exit 1
		;;
esac

# Exit from the script with success (0)
exit 0
