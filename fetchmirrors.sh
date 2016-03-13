#!/bin/bash

usage() {

	## Display help / usage options menu
	echo "${Yellow} Usage:${Green} $this <opts>"
	echo
	echo "${Yellow} Updates pacman mirrorlist directly from archlinux.org"
	echo " Options:"
	echo "${Green}   -c --country"
	echo "${Yellow}   Specify your country code:${Green} $this -c US"
	echo
	echo "${Green}   -d --nocolor"
	echo "${Yellow}   Disable color prompts"
	echo
	echo "${Green}   -h --help"
	echo "${Yellow}   Display this help message"
	echo
	echo "${Green}   -l --list"
	echo "${Yellow}   Display list of country codes"
	echo
	echo "${Green}   -q --noconfirm"
	echo "${Yellow}   Disable confirmation messages (Run $this automatically without confirm)"
	echo
	echo "${Green}   -s --servers"
	echo "${Yellow}   Number of servers to add to ranked list (default is 6)"
	echo
	echo "${Green}   -v --verbose"
	echo "${Yellow}   Verbose output"
	echo
	echo "${Yellow}Use${Green} $this ${Yellow}without any option to prompt for country code${ColorOff}"
}

list() {
	
	## Display list of country codes to user in terminal
	echo "${Yellow}Country codes:${ColorOff}"
	echo "$countries" | column -t
	echo
	echo "${Yellow}Note: Use only the upercase two character code in your command ex:${Green} $this -c US"
	echo "${Yellow}Or simply use:${Green} ${this}${ColorOff}"

}

get_opts() {
	
	## Set this variable and countries variable
	this=${0##*/}
	confirm=true
	err=$(echo "${Red}Error: ${Yellow}please select a number from the list.${ColorOff}")
	countries=$(echo -e "1) AT Austria - 2) AU  Australia - 3) BE Belgium\n4) BG Bulgaria - 5) BR Brazil - 6) BY Belarus\n7) CA Canada - 8) CL Chile - 9) CN China \n10) CO Columbia - 11) CZ Czech-Republic - 12) DE Germany\n13) DK Denmark - 14) EE Estonia - 15) ES Spain\n16) FI Finland - 17) FR France - 18) GB United-Kingdom\n19) HU Hungary - 20) IE Ireland - 21) IL Isreal\n22) IN India - 23) IT Italy - 24) JP Japan\n25) KR Korea - 26) KZ Kazakhstan - 27) LK Sri-Lanka\n28) LU Luxembourg - 29) LV Lativia - 30) MK Macedonia\n31) NC New-Caledonia - 32) NL Netherlands - 33) NO Norway\n34) NZ New-Zealand - 35) PL Poland - 36) PT Portugal\n37) RO Romania - 38) RS Serbia - 39) RU Russia\n40) SE Sweden - 41) SG Singapore - 42) SK Slovakia\n43) TR Turkey - 44) TW Taiwan - 45) UA Ukraine\n46) US United-States - 47) UZ Uzbekistan - 48) VN Viet-Nam\n49) ZA South-Africa - 50) AM All-Mirrors - 51) AS All-Https")
	
	## Set colors is user selects nocolor option disable color
	if (<<<$* grep -w "\-\-nocolor\|\-d" &> /dev/null); then
		Green=$'\e[0m';
		Yellow=$'\e[0m';
		Red=$'\e[0m';
		ColorOff=$'\e[0m';
	else
		Green=$'\e[0;32m';
		Yellow=$'\e[0;33m';
		Red=$'\e[0;31m';
		ColorOff=$'\e[0m';
	fi

	if (<<<$* grep -w "\-\-verbose\|\-v" &> /dev/null); then
		verbose=true
	else
		verbose=false
	fi

	if (<<<$* grep -w "\-\-servers\|\-s" &> /dev/null); then
		rank_int=$(<<<$*  grep -o "[0-9]\|[0-9][0-9]")
		if ! (<<<"$rank_int" grep "^-\?[0-9]*$" &> /dev/null) || [ -z "$rank_int" ]; then
			echo
			echo "${Red}Error: ${Yellow} invalid number of ranked servers specified ${rank_int}${ColorOff}"
			exit 1
		fi
	else
		rank_int="6"
	fi
	
	if (<<<$* grep -w "\-\-noconfirm\|\-q" &> /dev/null); then
		confirm=false
	fi

	while (true)
	  do
		case "$1" in
			-n|--nocolor) shift
			;;
			-q|--noconfirm) shift
			;;
			-s|--server) shift ; shift
			;;
			-v|--verbose) shift
			;;
			-l|--list) 
				list
				break
			;;
			-h|--help)
				usage
				break
			;;
			-c|--country)
				if [ -z "$2" ]; then
					echo "${Red}Error: ${Yellow}You must enter a country code."
					echo
				elif (<<<"$countries" grep -w "$2" &> /dev/null); then
					country_code="$2"
					query="https://www.archlinux.org/mirrorlist/?country=${country_code}"
					get_list
				else
					echo "${Red}Error: ${Yellow}country code: $2 not found."
					echo "To view a list of country codes run:${Green} fetchmirrors -l${ColorOff}"
					echo
				fi
				break
			;;
			*)
				search
				break
			;;
		esac
	done
	exit

}

search() {
	
	while (true)
	  do
		echo "${Yellow}Country codes:${ColorOff}"
		echo "$countries" | column -t
		echo
		echo -n "${Yellow}Enter the number corresponding to your country code ${Green}[1,2,3...]${Yellow}:${ColorOff} "
		read input

		if [ "$input" -gt "51" ]; then
			echo
			echo "$err"
		elif ! (<<<$input grep "^-\?[0-9]*$" &>/dev/null); then
			echo
			echo "$err"
		else
			break
		fi
	done
			
	if [ "$input" -eq "50" ]; then
		country_code="All"
		query="https://www.archlinux.org/mirrorlist/all/"
	elif [ "$input" -eq "51" ]; then
		country_code="All HTTPS"
		query="https://www.archlinux.org/mirrorlist/all/https"
	else
		country_code=$(echo "$countries" | grep -o "$input...." | awk '{print $2}')
		query="https://www.archlinux.org/mirrorlist/?country=${country_code}"
	fi

	if "$confirm" ; then
		echo
		echo -n "${Yellow}You have selected the country code:${Green} $country_code ${Yellow}- is this correct ${Green}[y/n]:${ColorOff} "
		read input
		case "$input" in
			y|Y|yes|Yes|yY|Yy|yy|YY)
				get_list
			;;
			*)
				search
			;;
		esac
	else
		get_list
	fi

}

get_list() {

	if [ -f /usr/bin/wget ]; then
		echo
		echo "${Yellow}Fetching new mirrorlist from:${Green} ${query}${ColorOff}"
		wget -O /tmp/mirrorlist "$query" &> /dev/null
	else
		echo
		echo "${Yellow}Fetching new mirrorlist from:${Green} ${query}${ColorOff}"
		curl -o /tmp/mirrorlist "$query" &> /dev/null
	fi
	sed -i 's/#//' /tmp/mirrorlist

	echo
	echo "${Yellow}Please wait while ranking${Green} $country_code ${Yellow}mirrors...${ColorOff}"
	
	if "$verbose" ;  then
		rankmirrors -v -n $rank_int /tmp/mirrorlist &> /tmp/mirrorlist.ranked
		if [ "$?" -gt "0" ]; then
			echo "${Red}Error: an error occured in ranking mirrorlist exiting..."
			exit 1
		fi
	else
		rankmirrors -n $rank_int /tmp/mirrorlist > /tmp/mirrorlist.ranked
		if [ "$?" -gt "0" ]; then
			echo "${Red}Error: an error occured in ranking mirrorlist exiting..."
			exit 1
		fi

	fi

	if "$confirm" ; then
		echo
		echo -n "${Yellow}Would you like to view new mirrorlist? ${Green}[y/n]: ${ColorOff}"
		read input

		case "$input" in
			y|Y|yes|Yes|yY|Yy|yy|YY)
				echo
				cat /tmp/mirrorlist.ranked
			;;
		esac

		echo
		echo -n "${Yellow}Would you like to install the new mirrorlist backing up existing? ${Green}[y/n]:${ColorOff} "
		read input
	else
		input="y"
	fi
		
	case "$input" in
		y|Y|yes|Yes|yY|Yy|yy|YY)
			sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
			sudo mv /tmp/mirrorlist.ranked /etc/pacman.d/mirrorlist
			cleanup
			echo
			echo "${Green}New mirrorlist installed ${Yellow}- Old mirrorlist backed up to /etc/pacman.d/mirrorlist.bak${ColorOff}"
			echo
		;;
		*)
			cleanup
			echo
			echo "${Yellow}Mirrorlist was not installed - exiting...${ColorOff}"
			echo
		;;
	esac

}

cleanup() {

rm /tmp/{mirrorlist,mirrorlist.ranked} &> /dev/null

}

get_opts "$@"
