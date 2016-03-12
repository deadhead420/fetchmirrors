#!/bin/bash

usage() {

	## Display help / usage options menu
	echo "${Yellow} Usage:${Green} $this <opts>"
	echo
	echo "${Yellow} Updates pacman mirrorlist directly from archlinux.org"
	echo
	echo " Options:"
	echo "${Green}   -c --country"
	echo "${Yellow}   Specify your country code:${Green} $this -c US"
	echo
	echo "   -l --list"
	echo "${Yellow}   Display list of country codes"
	echo
	echo "${Green}   -n --nocolor"
	echo "${Yellow}   Disable color prompts"
	echo
	echo "${Green}   -h --help"
	echo "${Yellow}   Display this help message"
	echo
	echo "${Yellow}Use${Green} $this ${Yellow}command without any options to be prompted for country code from list${ColorOff}"
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
	countries=$(echo -e "1) AT Austria - 2) AU  Australia - 3) BE Belgium\n4) BG Bulgaria - 5) BR Brazil - 6) BY Belarus\n7) CA Canada - 8) CL Chile - 9) CN China \n10) CO Columbia - 11) CZ Czech-Republic - 12) DE Germany\n13) DK Denmark - 14) EE Estonia - 15) ES Spain\n16) FI Finland - 17) FR France - 18) GB United-Kingdom\n19) HU Hungary - 20) IE Ireland - 21) IL Isreal\n22) IN India - 23) IT Italy - 24) JP Japan\n25) KR Korea - 26) KZ Kazakhstan - 27) LK Sri-Lanka\n28) LU Luxembourg - 29) LV Lativia - 30) MK Macedonia\n31) NC New-Caledonia - 32) NL Netherlands - 33) NO Norway\n34) NZ New-Zealand - 35) PL Poland - 36) PT Portugal\n37) RO Romania - 38) RS Serbia - 39) RU Russia\n40) SE Sweden - 41) SG Singapore - 42) SK Slovakia\n43) TR Turkey - 44) TW Taiwan - 45) UA Ukraine\n46) US United-States - 47) UZ Uzbekistan - 48) VN Viet-Nam\n49) ZA South-Africa")
	
	## Set colors is user selects nocolor option disable color
	if (<<<$* grep "\-\-nocolor\|\-n" &> /dev/null); then
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

	case "$*" in
		$(<<<"$*" grep "\-l\|\-\-list")) list
		;;
		$(<<<"$*" grep "\-h\|\-\-help")) usage
		;;
		$(<<<"$*" grep "\-c\|\-\-country"))
			if (<<<$countries grep -o "$2" &> /dev/null); then
				country_code="$2"
				get_list
			else
				echo
				echo "${Red}Error: ${Yellow}country code: $2 not found."
				echo "To view a list of country codes run:${Green} fetchmirrors -l${ColorOff}"
				echo
			fi
		;;
		*)
			search
		;;
	esac

}

search() {
	
	while (true)
	  do
		echo "${Yellow}Country codes:${ColorOff}"
		echo "$countries" | column -t
		echo
		echo -n "${Yellow}Enter the number corresponding to your country code ${Green}[1,2,3...]${Yellow}:${ColorOff} "
		read input

		if [ "$input" -gt "49" ]; then
			echo
			echo "${Red}Error: ${Yellow}please select a number from the list.${ColorOff}"
		else
			country_code=$(echo "$countries" | grep -o "$input...." | awk '{print $2}')
			echo
			echo -n "${Yellow}You have selected the country code:${Green} $country_code ${Yellow}- is this correct ${Green}[y/n]:${ColorOff} "
			read input
			case "$input" in
				y|Y|yes|Yes|yY|Yy|yy|YY)
					break
				;;
			esac
		fi
	done

	get_list

}

get_list() {

	if [ -f /usr/bin/wget ]; then
		echo
		echo "${Yellow}Fetching new mirrorlist from:${Green} www.archlinux.org/mirrorlist/?country=${country_code}${ColorOff}"
		wget -O /tmp/mirrorlist "https://www.archlinux.org/mirrorlist/?country=$country_code&protocol=http&ip_version=4" &> /dev/null
	else
		echo
		echo "${Yellow}Fetching new mirrorlist from:${Green} www.archlinux.org/mirrorlist/?country=${country_code}${ColorOff}"
		curl -o /tmp/mirrorlist "https://www.archlinux.org/mirrorlist/?country=$country_code&protocol=http&ip_version=4" &> /dev/null
	fi
	sed -i 's/#//' /tmp/mirrorlist

	echo
	echo "${Yellow}Please wait while ranking${Green} $country_code mirrors...${ColorOff}"
	rankmirrors -n 6 /tmp/mirrorlist > /tmp/mirrorlist.rank

	echo
	echo -n "${Yellow}Would you like to view new mirrorlist? ${Green}[y/n]: ${ColorOff}"
	read input

	case "$input" in
		y|Y|yes|Yes|yY|Yy|yy|YY)
			echo
			cat /tmp/mirrorlist.rank
		;;
	esac

	echo
	echo -n "${Yellow}Would you like to install the new mirrorlist backing up existing? ${Green}[y/n]:${ColorOff} "
	read input

	case "$input" in
		y|Y|yes|Yes|yY|Yy|yy|YY)
			sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
			sudo mv /tmp/mirrorlist.rank /etc/pacman.d/mirrorlist
			echo
			echo "${Green}New mirrorlist installed ${Yellow}- Old mirrorlist backed up to /etc/pacman.d/mirrorlist.bak${ColorOff}"
			echo
		;;
		*)
			echo
			echo "${Yellow}Mirrorlist was not installed - exiting...${ColorOff}"
			echo
		;;
	esac

}

get_opts "$@"