#!/bin/bash
###############################################################
### fetchmirrors.sh pacman mirrorlist update utility
###
### Copyright (C) 2017 Dylan Schacht
###
### By: Dylan Schacht (deadhead)
### Email: deadhead3492@gmail.com
### Webpage: http://arch-anywhere.org
###
### Any questions, comments, or bug reports may be sent to above
### email address. Enjoy, and keep on using Arch.
###
### License: GPL v2.0
###############################################################

usage() {

	echo "${Yellow} Updates pacman mirrorlist directly from archlinux.org"
	echo
	echo "${Yellow} Usage:${Green} $this <opts> <args> ${Yellow}Ex: ${Green}${this} -q -s 4 -c US" # Display help / usage options menu
	echo
	echo " Options:"
	echo "${Green}   -c --country"
	echo "${Yellow}   Specify your country code(s):${Green} $this -c US AU"
	echo "${Green}   -d --nocolor"
	echo "${Yellow}   Disable color prompts"
	echo "${Green}   -h --help"
	echo "${Yellow}   Display this help message"
	echo "${Green}   -l --list"
	echo "${Yellow}   Display list of country codes"
	echo "${Green}   -q --noconfirm"
	echo "${Yellow}   Disable confirmation messages"
	echo "${Green}   -s --servers"
	echo "${Yellow}   Number of servers to rank (default  6)"
	echo "${Green}   -v --verbose"
	echo "${Yellow}   Verbose output"
	echo
	echo "${Yellow} Use${Green} $this ${Yellow}without any option to prompt for country code(s)${ColorOff}"
}

get_opts() {

	this=${0##*/} # Set 'this', 'rank_int', 'confirm', 'countries', and color variables
	rank_int="6"
	confirm=true
	err=false
	Green=$'\e[0;32m';
	Yellow=$'\e[0;33m';
	Red=$'\e[0;31m';
	Magenta=$'\e[0;35m';
	ColorOff=$'\e[0m';
#	frmt_countries=( "${Magenta}1) ${Green}AM ${Yellow}All-Mirrors - ${Magenta}2) ${Green}AS ${Yellow}All-Https - ${Magenta}3) ${Green}AT ${Yellow}Austria\n${Magenta}4) ${Green}AU ${Yellow}Australia - ${Magenta}5) ${Green}BE ${Yellow}Belgium - ${Magenta}6) ${Green}BG ${Yellow}Bulgaria\n${Magenta}7) ${Green}BR ${Yellow}Brazil - ${Magenta}8) ${Green}BY ${Yellow}Belarus - ${Magenta}9) ${Green}CA ${Yellow}Canada\n${Magenta}10) ${Green}CL ${Yellow}Chile - ${Magenta}11) ${Green}CN ${Yellow}China - ${Magenta}12) ${Green}CO ${Yellow}Columbia\n${Magenta}13) ${Green}CZ ${Yellow}Czech-Republic - ${Magenta}14) ${Green}DE ${Yellow}Germany - ${Magenta}15) ${Green}DK ${Yellow}Denmark\n${Magenta}16) ${Green}EE ${Yellow}Estonia - ${Magenta}17) ${Green}ES ${Yellow}Spain - ${Magenta}18) ${Green}FI ${Yellow}Finland\n${Magenta}19) ${Green}FR ${Yellow}France - ${Magenta}20) ${Green}GB ${Yellow}United-Kingdom - ${Magenta}21) ${Green}HU ${Yellow}Hungary\n${Magenta}22) ${Green}IE ${Yellow}Ireland - ${Magenta}23) ${Green}IL ${Yellow}Isreal - ${Magenta}24) ${Green}IN ${Yellow}India\n${Magenta}25) ${Green}IT ${Yellow}Italy - ${Magenta}26) ${Green}JP ${Yellow}Japan - ${Magenta}27) ${Green}KR ${Yellow}Korea\n${Magenta}28) ${Green}KZ ${Yellow}Kazakhstan - ${Magenta}29) ${Green}LK ${Yellow}Sri-Lanka - ${Magenta}30) ${Green}LU ${Yellow}Luxembourg\n${Magenta}31) ${Green}LV ${Yellow}Lativia - ${Magenta}32) ${Green}MK ${Yellow}Macedonia - ${Magenta}33) ${Green}NC ${Yellow}New-Caledonia\n${Magenta}34) ${Green}NL ${Yellow}Netherlands - ${Magenta}35) ${Green}NO ${Yellow}Norway - ${Magenta}36) ${Green}NZ ${Yellow}New-Zealand\n${Magenta}37) ${Green}PL ${Yellow}Poland - ${Magenta}38) ${Green}PT ${Yellow}Portugal - ${Magenta}39) ${Green}RO ${Yellow}Romania\n${Magenta}40) ${Green}RS ${Yellow}Serbia - ${Magenta}41) ${Green}RU ${Yellow}Russia - ${Magenta}42) ${Green}SE ${Yellow}Sweden\n${Magenta}43) ${Green}SG ${Yellow}Singapore - ${Magenta}44) ${Green}SK ${Yellow}Slovakia - ${Magenta}45) ${Green}TR ${Yellow}Turkey\n${Magenta}46) ${Green}TW ${Yellow}Taiwan - ${Magenta}47) ${Green}UA ${Yellow}Ukraine - ${Magenta}48) ${Green}US ${Yellow}United-States\n${Magenta}49) ${Green}UZ ${Yellow}Uzbekistan - ${Magenta}50) ${Green}VN ${Yellow}Viet-Nam - ${Magenta}51) ${Green}ZA ${Yellow}South-Africa" )
	countries=( "1) AM All-Mirrors - 2) AS All-Https - 3) AT Austria\n4) AU Australia - 5) BE Belgium - 6) BG Bulgaria\n7) BR Brazil - 8) BY Belarus - 9) CA Canada\n10) CL Chile - 11) CN China - 12) CO Columbia\n13) CZ Czech-Republic - 14) DE Germany - 15) DK Denmark\n16) EE Estonia - 17) ES Spain - 18) FI Finland\n19) FR France - 20) GB United-Kingdom - 21) HU Hungary\n22) IE Ireland - 23) IL Isreal - 24) IN India\n25) IT Italy - 26) JP Japan - 27) KR Korea\n28) KZ Kazakhstan - 29) LK Sri-Lanka - 30) LU Luxembourg\n31) LV Lativia - 32) MK Macedonia - 33) NC New-Caledonia\n34) NL Netherlands - 35) NO Norway - 36) NZ New-Zealand\n37) PL Poland - 38) PT Portugal - 39) RO Romania\n40) RS Serbia - 41) RU Russia - 42) SE Sweden\n43) SG Singapore - 44) SK Slovakia - 45) TR Turkey\n46) TW Taiwan - 47) UA Ukraine - 48) US United-States\n49) UZ Uzbekistan - 50) VN Viet-Nam - 51) ZA South-Africa" )

	trap ctrl_c INT

    if [ -z "$1" ] && [ "$UID" -ne "0" ]; then
        usage ; exit 0
    elif [ "$UID" -ne "0" ]; then
       echo -e "\n${Yellow}[${this}]${Red} Error: ${Yellow}YOU MUST BE ROOT TO USE THIS!"
       echo -e "${Magenta}Tip: ${Yellow}Precede your command with 'sudo'${ColorOff}\n"
       exit 1
    fi

	if [ -f /tmp/mirrorlist ]; then
		rm /tmp/mirrorlist
	fi

	while (true) # Loop case statement on 1 parameter until something happens (break || exit 1)
	  do
		case "$1" in
			-d|--nocolor) # Disable color prompts
				unset Green Yellow Red Magenta ColorOff ; shift
			;;
			-q|--noconfirm) # Disable confirmation messages
				confirm=false ; shift
			;;
			-s|--server) # Specify number of servers to add to rank list output
				rank_int="$2"
				if ! (<<<"$rank_int" grep "^-\?[0-9]*$" &> /dev/null) || [ -z "$rank_int" ]; then
					echo "${Yellow}[${this}]${Red} Error: ${Yellow} invalid number of servers specified ${rank_int}${ColorOff}"
					exit 1
				fi
				shift ; shift
			;;
			-v|--verbose) # Set verbose switch on
				rank_int="$rank_int -v" ; shift
			;;
			-l|--list) # Display a list of country codes to the user
				echo "${Yellow}Country codes:${ColorOff}"
				echo -e "$countries" | column -t
				echo "${Yellow}Note: Use only the upercase two character code in your command ex:${Green} $this -c US"
				echo "${Yellow}Or simply use:${Green} ${this}${ColorOff}"
				break
			;;
			-h|--help) # Display usage message
				usage ; break
			;;
			-c|--country) # Country parameter allows user to input country code (ex: US)
				if [ -z "$2" ]; then
					echo "${Yellow}[${this}]${Red} Error: ${Yellow}You must enter a country code."
				else
					shift
					for i in $(echo "$@") ; do
						if (echo "$countries" | grep -w "$i" &> /dev/null); then
							query+="https://www.archlinux.org/mirrorlist/?country=${i} "
						else
							echo "${Yellow}[${this}]${Red} Error: ${Yellow}country code: $2 not found."
							echo "To view a list of country codes run:${Green} $this -l${ColorOff}"
							exit 1
						fi
					done
					get_list
				fi
				break
			;;
			"") # Empty 1 parameter means search for country code
				search ; break
			;;
			*) # Take anything else as invalid input
				echo "${Yellow}[${this}]${Red} Error: ${Yellow}unknown input $1 exiting...${ColorOff}"
				exit 1
		esac
	done # End case options loop
	exit

}

search() {

	while (true)
	  do
		echo "${Green}Country codes:${ColorOff}"
		echo -e "$countries" | column -t
		echo -n "${Yellow}Enter the number(s) or code(s) corresponding to your country ${Green}[4 9 US]${Yellow}:${ColorOff} "
		read code

		for i in $(echo "$code") ; do
			case "$i" in
				1)	# Set query to all mirrors
					country="All"
					query="https://www.archlinux.org/mirrorlist/all/"
					break
				;;
				2)	# Set query to all https mirrors
					country="All HTTPS"
					query="https://www.archlinux.org/mirrorlist/all/https/"
					break
				;;
				[0-9]|[1-4][0-9]|[5][0-1])
					country_code=$(<<<"$countries" grep -o "$i.*" | awk 'NR==1 {print $2}')
					country+=$(<<<"$countries" grep -o "$i.*" | awk 'NR==1 {print $3" "}' | sed 's/\\n.*/ /')
					query+="https://www.archlinux.org/mirrorlist/?country=${country_code} "
				;;
				[A-Z][A-Z])
					if (<<<"$countries" grep -o "$i" &>/dev/null); then
						country+=$(<<<"$countries" grep -o "$i.*" | awk 'NR==1 {print $2}' | sed 's/\\n.*/ /')
						query+="https://www.archlinux.org/mirrorlist/?country=${i} "
					else
						echo "${Yellow}[${this}]${Red} Error: ${Yellow}invalid input [ $i ], select a number or code from the list.${ColorOff}"
						err=true
						break
					fi
				;;
				*)
					echo "${Yellow}[${this}]${Red} Error: ${Yellow}invalid input [ $i ], select a number or code from the list.${ColorOff}"
					err=true
					break
				;;
			esac
		done

		if ! "$err" ; then
			break
		else
			unset country query
			err=false
		fi
	done

	if "$confirm" ; then
		echo -en "\n${Yellow}You have selected the countries:${Green} $country${Yellow}- is this correct ${Green}[Y/n]:${ColorOff} "
		read input

		case "$input" in
			y|Y|yes|Yes|yY|Yy|yy|YY|"")
				get_list
			;;
			*)	unset country query
				search
			;;
		esac
	else
		get_list
	fi

}

get_list() {

	echo
	for list in $(echo "$query") ; do
		if (curl -s "$list" | grep "Server" &>/dev/null); then
			echo "${Yellow}Fetching new mirrorlist from:${Green} ${list}${ColorOff}"
			curl -s "$list" | sed '1,4d' >> /tmp/mirrorlist
		elif (grep "Server" /tmp/mirrorlist &>/dev/null); then
			echo -e "${Yellow}[${this}]${Red} Error: ${Yellow} Failed fetching mirrorlist from:${ColorOff} $list"
			echo "${Yellow}Skipping...${ColorOff}"
		else
			echo -e "${Yellow}[${this}]${Red} Error: ${Yellow} Failed fetching mirrorlist from:${ColorOff} $list"
			exit 1
		fi
	done

	sed -i 's/#//' /tmp/mirrorlist
	echo "${Yellow}Please wait while ranking${Green} $country${Yellow}mirrors...${ColorOff}"
	rankmirrors -n "$rank_int" /tmp/mirrorlist > /tmp/mirrorlist.ranked

	if [ "$?" -gt "0" ]; then
		echo "${Yellow}[${this}]${Red} Error: ${Yellow}an error occured in ranking mirrorlist exiting..."
		rm /tmp/{mirrorlist,mirrorlist.ranked} &> /dev/null
		exit 1
	elif "$confirm" ; then
		echo -en "\n${Yellow}Would you like to view new mirrorlist? ${Green}[Y/n]: ${ColorOff}"
		read input

		case "$input" in
			y|Y|yes|Yes|yY|Yy|yy|YY|"")
				echo ; cat /tmp/mirrorlist.ranked
			;;
		esac

		echo -en "\n${Yellow}Would you like to install the new mirrorlist backing up existing? ${Green}[Y/n]:${ColorOff} "
		read input
	else
		input=""
	fi

	case "$input" in
		y|Y|yes|Yes|yY|Yy|yy|YY|"")
			mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
			mv /tmp/mirrorlist.ranked /etc/pacman.d/mirrorlist
			echo "${Green}New mirrorlist installed ${Yellow}- Old mirrorlist backed up to /etc/pacman.d/mirrorlist.bak${ColorOff}"
			rm /tmp/mirrorlist &> /dev/null
		;;
		*)
			echo "${Yellow}Mirrorlist was not installed - exiting...${ColorOff}"
			rm /tmp/{mirrorlist,mirrorlist.ranked} &> /dev/null
		;;
	esac

}

ctrl_c() {

	if [ -f /tmp/mirrorlist ]; then
		rm -r /tmp/mirrorlist*
		exit 1
	fi

}

get_opts "$@"
