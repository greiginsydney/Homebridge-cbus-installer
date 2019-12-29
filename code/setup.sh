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


copy_groups ()
{
	# https://stackoverflow.com/questions/24998434/read-command-display-the-prompt-in-color-or-enable-interpretation-of-backslas
	# See "88/256 Colors": https://misc.flogisoft.com/bash/tip_colors_and_formatting
	GREEN="\033[38;5;10m"
	YELLOW="\033[38;5;11m"
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
			echo ${BASH_REMATCH[1]}
			#Skip if it's already in the file:
			if grep -Fq "$thisGroup" /var/lib/homebridge/config.json;
			then
				echo 'Skipped: already in config.json'
				continue
			fi
			matchUnknown="\"type\":\ \"unknown\"(.+)"
			if [[ $thisGroup =~ $matchUnknown ]];
			then
				defaultChoice="c"
				read -p "$(echo -e "[a]dd, [s]kip, "$YELLOW"[C]hange & enable"$RESET", [q]uit? ")" choice
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
					echo "Added"
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
						read -p "[l]ight, s[w]itch, [d]immer, [s]hutter, [m]otion, s[e]curity, [t]rigger, [c]ontact: " newType
						case $newType in 
							(l|L) replaceValue="light" ;;
							(w|W) replaceValue="switch" ;;
							(d|D) replaceValue="dimmer";;
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
			#Skip if a changed value (e.g. from "Unknown") is already in the file:
			if grep -Fq "$thisGroup" /var/lib/homebridge/config.json;
			then
				echo 'Skipped: already in config.json'
				continue
			fi
			#Capture the line number of the last group:
			lastLine=$(sed -n -E '/^\s*\{.+\}$/=' /var/lib/homebridge/config.json)
			if [ ! -z "$lastLine" ];
			then
				# Add a trailing comma to what's *currently* the last group:
				sed -i -E "$lastLine s/^(\s*\{.+\}$)/\1,/"g /var/lib/homebridge/config.json
				((lastLine+=1)) #Move the index to the line after, where we'll insert a new one
				sed -i "$lastLine i\        {$thisGroup }" /var/lib/homebridge/config.json
			else
				#This might be a brand new file. Let's check:
				accessoriesCount=$(grep -Fc '"accessories": [ ]' /var/lib/homebridge/config.json)
				if [[ $accessoriesCount == 2 ]];
				then
					#Yes, it's a brand new file. Glue this first group into the first instance of '"accessories": [ ]'
					sed -i -E "0,/\"accessories\":\ \[\ \]/s/(\"accessories\":\ \[)\ \]/\1\n\        {$thisGroup }\n\      ]/" /var/lib/homebridge/config.json
				else
					echo ">> JSON error. config.json has no final assessory without a comma after it"
					echo ">> Please manually edit config.json and restart"
					echo ""
					break
				fi
			fi
		fi
	done 9</home/pi/my-platform.json
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
