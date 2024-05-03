#!/bin/bash

# ==================================================================================================
# CREATELAUNCHER.SH
# ==================================================================================================

# -[ USAGE ]----------------------------------------------------------------------------------------
# `./createLauncher` : Will silently create a launcher
# OPTIONS:
#     - `-v` : Will create a launcher by outputting to the terminal all the steps
#     - `--verbose` : Same as -v option
#     - `-l` : Will show all the previous launchers create by this script
#     - `--list` : Same as -l option
#     - `-r` : Allows deletion of launchers previously created by this script
#     - `--remove` : Same as -r option
#     - `-c` : Automatically create a launcher fot each google-chrome account found on the PC (if Google Chrome is installed)
#     - `--chrome` : Same as c
#     - `-f` : Automatically create a launcher fot each firefox account found on the PC (if Firefox is installed)
#     - `--firefox` : Same as f

# -[ ERROR DICT ]-----------------------------------------------------------------------------------
#ERROR 1 : end of cleanup fct, something goes wrong and cleanup function was called $>echo ${?}

ERROR=( # [01..09] Normal Exits
	"1":"in ft_exit fct, normal exit"
	"2":"in set_options fct, Unknowm argument"
	"3":"in set_options fct, incorrect combination of options: you can list and remove at the same time"
	# [10..19] Wrong Function's Usage
	"10":"in ft_exit fct, wrong usage:no args or more than one given"
	"11":"in check_package fct, wrong usage:invalid number of arguments of check_package function"
	"12":"in check_package fct, a command is not install and user does not want to install it"
	"13":"in get_value_from_user, wrong usage:invalid number of arguments of get_value_from_user function"
	"14":"in get_value_from_user, Zenity's Exit or Cancel buttom triggered in get_value_from_user"
	# [20..29] Fail of a bash command
	"20":"create_icon ftc did not create any icon."
	"21":"in select_image, identify cmd return an error"
	# [30..99] Cancel/Exit of Zenity's Windows
	"30":"Zenity Exit or Cancel when asking for folder/launcher's name"
	"31":"Zenity Exit or Cancel when asking if erase old folder with same Folder name or not"
	"32":"Zenity Exit or Cancel when asking for launcher's COMMENT value for the Destkop file"
	"33":"Zenity Exit or Cancel when asking for launcher's TYPE value for the Desktop file"
	"34":"Zenity Exit or Cancel when TYPE=APPLICATION, while asking if EXEC value is a command line or a script"
	"35":"Zenity Exit or Cancel when TYPE=APPLICATION and EXEC=script while browsing for the script"
	"36":"Zenity Exit or Cancel when TYPE=APPLICATION and EXEC=command line while asking for the command line"
	"37":"Zenity Exit or Cancel when TYPE=APPLICATION, while asking if EXEC should be execute in a terminal or not"
	"38":"Zenity Exit or Cancel when TYPE=LINK and while asking for EXEC value~(URL)"
	"39":"Zenity Exit or Cancel when TYPE=DIRECTORY and while asking for EXEC value~(PATH)"
	"40":"Zenity Exit or Cancel in select_image() when asking to choose between default or particular icon"
	"41":"Zenity Exit or Cancel in select_image() when browsing to select image to transform into an icon~(IMAGE_PATH)"
	"42":"Zenity Exit or Cancel in option --list when showing launcher's list"
	"43":"Zenity Exit or Cancel in option --list when their is no launcher in the list"
)

# =[ SETTINGS ]=====================================================================================
set -euo pipefail                      # Stop when cmd or pipe fail or if undefined variable is used
trap cleanup 1 2 3 6 ERR               # Exec cleanup when POSIX 1,2,3,6 or when script stop:ERR

# =[ VARIABLES ]====================================================================================
VERBOSE=0                                                        # When != 0 opt -v/--verbose is on
LISTING=0                                                        # When != 0 opt -l/--list is on
REMOVING=0                                                       # When != 0 opt -r/--remove is on
CHROME=0                                                         # When != 0 opt --chrome is on
FIREFOX=0                                                        # When != 0 opt --firefox is on
SLPWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd) # Script Localisation and new PWD
FOLDER_PATH="${HOME}/.local/share/applications/"                 # Where to create the folder
FOLDER_NAME=""                                                   # Name of your folder==launcher
EXEC=""                                                          # Cmd executed by launcher
ZWS="--width=500 --height=150"                                   # Zenity Windows Size

# =[ FUNCTIONS ]====================================================================================
# -[ CLEANUP ]--------------------------------------------------------------------------------------
function cleanup()
{
	# Call when something goes wrong, then clean the mess by removing our folder if created
	# Use ERROR dictionnary to print which error stop the script and calls cleanup function
	last_cmd=${?}
	ft_echo -e "\nSomething goes wrong => CLEANING UP:"
	for err in "${ERROR[@]}"; do
		k="${err%%:*}"
		v="${err##*:}"
		[ ${last_cmd} -eq ${k} ] && ft_echo -e "\t- ERROR ${k}:${v}\n"
	done
	# Remove folder
	if [[ -n ${FOLDER_NAME} && -d ${FOLDER_PATH}${FOLDER_NAME} ]]; then
		rm -vrf "${FOLDER_PATH}${FOLDER_NAME}"
	fi
	# Remove Temporary file
	if [[ -f ${temp_list_file} ]]; then
		rm -rf "${temp_list_file}"
	fi
	exit 01
}

# -[ EXIT ]-----------------------------------------------------------------------------------------
function ft_exit()
{
	# HomeMade exit function that return first arg as exit value
	# use to exit and be catch by trap(real exit will always be trap even with 0 value at the end)
	[[ ${#} -eq 1 ]] && return ${1} || return 10
}

# -[ ECHO ]-----------------------------------------------------------------------------------------
function ft_echo()
{
	# HomeMade echo function that print only if VERBOSE value not equal to 0
	[[ ${VERBOSE} -eq 0 ]] || echo ${@}
}

# -[ GET OPTIONS ]----------------------------------------------------------------------------------
function set_options()
{
	# Set option using getopts buildin cmd
	while getopts "vlrcf-:" opt;do
		case "${opt}" in
			-)
				case "${OPTARG}" in
					verbose) VERBOSE=1 ;;
					list) LISTING=1 ;;
					remove) REMOVING=1 ;;
					chrome) CHROME=1 ;;
					firefox) FIREFOX=1 ;;
				esac
				;;
			v) VERBOSE=1 ;;
			l) LISTING=1 ;;
			r) REMOVING=1 ;;
			c) CHROME=1 ;;
			f) FIREFOX=1 ;;
			?) # Long option's name
				ft_echo -e "\t- options UNKNOWN!"
				return 2;
				;;
		esac
	done
	if [ ${VERBOSE} -eq 1 ];then
		ft_echo -e "\nScript options:"
		[[ ${VERBOSE} -eq 1 ]] && ft_echo -e "\t-v/--verbose: Print all steps"
		[[ ${LISTING} -eq 1 ]] && ft_echo -e "\t-l/--list: List launchers created by this script"
		[[ ${REMOVING} -eq 1 ]] && ft_echo -e "\t-r/--remove: Remove a launcher created by this script"
		[[ ${CHROME} -eq 1 ]] && ft_echo -e "\t-c/--chrome: Google-Chrome launchers"
		[[ ${FIREFOX} -eq 1 ]] && ft_echo -e "\t-f/--firefox: FireFox launchers"
	fi
	[ $((${LISTING} + ${REMOVING})) -eq 2 ] && return 3 || return 0
}

# -[ GET VALUE FROM USER]---------------------------------------------------------------------------
function get_value_from_user()
{
	# `get_value_form_user arg1` Ask user the value of the variable ${arg1} then update it value.
	[[ ${#} -lt 1 || ${#} -gt 3 ]] && return 13
	[[ ${#} -gt 1 ]] && local title=${2} || local title="Change the value of \${${1}}"
	[[ ${#} -gt 2 ]] && local text=${3} || local text="Enter the new value you want to assign to the variable \${${1}}"
	tmp_value=$(zenity --entry --title="${title}" --text="${text}" ${ZWS}) && eval ${1}=\"${tmp_value}\" || return 14

}

# -[ CHECK REQUIREMENT PACKAGES ]-------------------------------------------------------------------
function check_function_from_package()
{
	# 'check_function_from_package [function] [package]` check if a fonction from a package is install, else ask 
	[[ $# -lt 1 || $# -gt 2 ]] && return 11
	cmd=$1
	[[ $# -eq 2 ]] && package=$2 || package=$1
	if ! which $1 > /dev/null; then
		echo "Command ${cmd} not found!Do you want to install ${package} with apt cmd?(y/n)"
		read
		if [ ${REPLY} == "y" ]; then
			sudo apt install $package
		else
			echo -e "Unfortunately, since ${package} is required to use this script and you don't want to install it, this script will stop here. :'("
			return 12
		fi
	else
		ft_echo -e "\t- ${cmd} is installed."
	fi
}

# -[ CHECK FOLDER BY DEFAULT XDG ]------------------------------------------------------------------
function check_default_xdg()
{
	# ASK user where to store our desktop file if ~/.local/share/applications doesn't exist
	if [[ -d ${FOLDER_PATH} ]]; then
		ft_echo -e "\t- '${FOLDER_PATH}' exist."
	else
		FOLDER_PATH=$(zenity --file-selection --directory --title="Select or Create the directory that will contains your launchers")
	fi
}

# -[ GET EXEC VALUE WHEN APPLICATION ] -------------------------------------------------------------
function get_exec_if_app()
{
	# If ask_type is an application, this function will ask to choose between a command line to execute or a script to launch.
	appOrCmd=$(zenity --list --title="Your application launch a Programm or execute a Command?" --column="Two choices:" "Browse folders for the executable" "Write the command line to run" ${ZWS}) || return 34
	while [ "${EXEC}" = "" ];do 
		if [[ "${appOrCmd}" == "Browse folders for the executable" ]];then
			EXEC=$(zenity --file-selection --title="Browse folders for the executable" --filename=${HOME}/) || return 35
		else
			get_value_from_user EXEC "Write the command line to run" "Write the command line to run" || return 36
			EXEC="sh -c ${EXEC}"
		fi
	done
	ask_term=$(zenity --list --title="Your application should be launch in a terminal?" --column="Two choices:" "Yes, it should be launch in a terminal" "No" ${ZWS}) || return 37
	[[ ${ask_term} == "No" ]] && TERM=false || TERM=true
}

# -[ CREATE IMAGE ]---------------------------------------------------------------------------------
function select_image()
{
	#Ask if user want an image by default or a particular one(only JPEG, XPM, SVG and PNG formats)
	ft_echo -e "\nSelect Image For Icon:"
	local question="Do you want to use a particular icon for this shortcut or do you want to use the default icons?"
	SPE_ICON=$(zenity --list --title="Particular or Default Icon:" --text "${question}" --column "Answers" "Default Icon" "Search this PC for a particular image." ${ZWS}) || return 40
	if [[ "${SPE_ICON}" == "Default Icon" ]];then
		[[ ${ASK_TYPE} == "Directory" ]] && IMAGE_PATH="${SLPWD}/Icons/dirIcon.png"
		[[ ${ASK_TYPE} == "Link" ]] && IMAGE_PATH="${SLPWD}/Icons/linkIcon.png"
		[[ ${ASK_TYPE} == "Application" ]] && IMAGE_PATH="${SLPWD}/Icons/appIcon.png"
		ft_echo -e "\t- Default Icon=\'${IMAGE_PATH}\'"
	else
		# ask for a path to an image that can be used as an icon until it is
		image_format=''
		while ([ "${image_format}" == "" ] || ([ "${image_format}" != "JPEG" ] && [ "${image_format}" != "XPM" ] && [ "${image_format}" != "SVG" ] && [ "${image_format}" != "PNG" ]));do 
			IMAGE_PATH=$(zenity --file-selection --title="Select the image to turn into an icon" --filename=/home/) || return 41
			image_format=$(identify -format '%m' ${IMAGE_PATH}) || return 21
		done
		ft_echo -e "\t- New Image=\'${IMAGE_PATH}\'"
	fi
}

# -[ CREATE ICON ]----------------------------------------------------------------------------------
function create_icon()
{
	#Resize the ${IMAGE_PATH} to a square images of 512*512 max
	local long=$(identify -format '%W' ${IMAGE_PATH})
	local larg=$(identify -format '%H' ${IMAGE_PATH})
	local iconPath="${FOLDER_PATH}${FOLDER_NAME}/"
	if [ ${long} -gt 512 ] && [ ${larg} -gt 512 ];then
		local iconFormat=512x512
		local iconName="${FOLDER_NAME}_512x512.png"
	elif [ ${long} -lt ${larg} ];then
		local iconFormat=${long}x${long}
		local iconName="${FOLDER_NAME}_${long}x${long}.png"
	else
		local iconFormat=${larg}x${larg}
		local iconName="${FOLDER_NAME}_${larg}x${larg}.png"
	fi
	iconFullName=${iconPath}${iconName}
	convert ${IMAGE_PATH} -resize ${iconFormat}! ${iconFullName}
}

# ==================================================================================================
# MAIN
# ==================================================================================================
# -[ OPTIONS ]======================================================================================
set_options ${@}

# -[ MAIN ]=========================================================================================
if [ ${LISTING} -ne 0 ]; then
	LAUNCHERS_LIST=()
	if [ ${CHROME} -ne 0 ] && [ ${FIREFOX} -eq 0 ]; then
		LTYPE="Chrome"
		LTITLE="Google-chrome launchers"
		for dir in $(find ${FOLDER_PATH}* -type d  | xargs -I {} basename "{}");do 
			[[ *"chrome"* == "${dir}" ]] && LAUNCHERS_LIST+=(${dir})
		done
	elif [ ${CHROME} -eq 0 ] && [ ${FIREFOX} -ne 0 ]; then
		LTYPE="Firefox"
		LTITLE="Firefox launchers"
		for dir in $(find ${FOLDER_PATH}* -type d  | xargs -I {} basename "{}");do 
			[[ *"firefox"* == "${dir}" ]] && LAUNCHERS_LIST+=(${dir})
		done
	elif [ ${CHROME} -ne 0 ] && [ ${FIREFOX} -ne 0 ]; then
		LTYPE="Chrome or Firefox"
		LTITLE="Google-chrome and Firefox launchers"
		for dir in $(find ${FOLDER_PATH}* -type d  | xargs -I {} basename "{}");do 
			[[ *"chrome"* == "${dir}" || *"firefox"* == "${dir}" ]] && LAUNCHERS_LIST+=(${dir})
		done
	else
		LTYPE=""
		LTITLE="List of all the launchers created by this script"
		for dir in $(find ${FOLDER_PATH}* -type d | xargs -I {} basename "{}");do LAUNCHERS_LIST+=(${dir});done
	fi
	if [[ ${#LAUNCHERS_LIST[@]} -ne 0 ]];then
		#zenity --list --multiple --title="${LTITLE}" --column="Launchers" ${LAUNCHERS_LIST[@]} || ft_exit 42
		temp_list_file=$(mktemp "/tmp/MCDL_list.XXXXXX")
		echo -e "List of ${LTYPE} launchers" >> ${temp_list_file}
		for l in ${LAUNCHERS_LIST[@]};do
			echo -ne "\t- ${l} " >> ${temp_list_file}
			echo : $(grep -E ^Comment= ${FOLDER_PATH}${l}/${l}.desktop | sed 's/^Comment=//') >> ${temp_list_file}
		done
		zenity --text-info --title="List of ${LTYPE} launchers" --filename=${temp_list_file} --ok-label="DOKI" --cancel-label="OKI" --width=300 --height=300 || ft_exit 42
		[ -f ${temp_list_file} ] && rm -rf "${temp_list_file}"
	else
		zenity --warning --title "No ${LTYPE} launcher" --text "No ${LTYPE} launcher" || ft_exit 43
	fi
elif [ ${REMOVING} -ne 0 ]; then
	if [ ${CHROME} -ne 0 ] && [ ${FIREFOX} -eq 0 ]; then
		echo remove only google-chrome launchers
	elif [ ${CHROME} -eq 0 ] && [ ${FIREFOX} -ne 0 ]; then
		echo remove only firefox launchers
	elif [ ${CHROME} -ne 0 ] && [ ${FIREFOX} -ne 0 ]; then
		echo remove only chrome and firefox launchers
	else
		echo remove select windows
	fi
elif [ ${CHROME} -ne 0 ]; then
	echo create google-chrome launchers
elif [ ${FIREFOX} -ne 0 ]; then
	echo create firefox launchers
else
	# -[ CHECKS COMMANDES ]=========================================================================
	# -[ CHECK PACKAGES NEEDED ]--------------------------------------------------------------------
	ft_echo "Check Requirements Packages:"
	check_function_from_package xdg-open xdg-utils                           # CheckIf xdg-open cmd from xdg-utils package is available
	check_function_from_package zenity                                       # CheckIf zenity cmd is available 
	check_function_from_package identify imagemagick                         # CheckIf identify cmd from imagemagick package is available
	check_function_from_package convert imagemagick                          # CheckIf convert cmd from imagemagick package is available
	check_function_from_package xdg-open xdg-utils                           # CheckIf xdg-command cmd from xdg-utils package is available
	check_function_from_package update-desktop-database desktop-file-utils   # CheckIf package dekstop-file-utils is available
	# -[ CHECK DEFAULT XDG FOLDER ]-----------------------------------------------------------------
	ft_echo -e "\nCheck Default Folder Localisation:"
	check_default_xdg                                                        # CheckIf XDG default folder exist, else ask user to define one

	# -[ CREATE CUSTOM LAUNCHER ]===================================================================
	# -[ GET INFORMATIONS FROM USER ]---------------------------------------------------------------
	# Ask a launcher/folder name while it's empty or folder's name already taken, if already taken then you can erase the older or choose another name
	while ([ -d "${FOLDER_PATH}${FOLDER_NAME}" ] || [ -z "${FOLDER_NAME}" ]);do
		if [ -z "${FOLDER_NAME}" ];then
			get_value_from_user FOLDER_NAME "Choose launcher's name" "Please, enter the name of your launcher" || ft_exit 30
		fi
		if [ -d "${FOLDER_PATH}${FOLDER_NAME}" ];then
			TEMP=${FOLDER_NAME} && FOLDER_NAME='' # Use TEMP in order to not rm folder with cleanup fct if ask_erase's zenity page is exit or cancel.
			ASK_ERASE=$(zenity --list --title="Name already taken!!" --column="Would you like to delete the existing launcher:" "Yes, erase it" "No" ${ZWS}) || ft_exit 31
			if [[ ${ASK_ERASE} != "No" ]]; then
				FOLDER_NAME=${TEMP}
				rm -rf ${FOLDER_PATH}${FOLDER_NAME}
			fi
		fi
	done
	FOLDER_NAME=${FOLDER_NAME//\ /_}                                         # Replace spaces by underscores in folder's name

	# Ask for a description
	get_value_from_user COMMENT "(OPTIONNAL):ADD some comment" "Tooltip for the entry, for example 'View sites on the Internet'." || ft_exit 32

	# Ask to choose between Types                                            # ADD type
	ASK_TYPE=$(zenity --list --title="Select the Type" --text "You want to create a launcher for:" --column "Answers" "Application" "Link" "Directory") || ft_exit 33

	# Ask the type : DEFINE EXEC
	[[ "${ASK_TYPE}" == "Application" ]] && get_exec_if_app
	if [ "${ASK_TYPE}" == "Link" ];then
		get_value_from_user EXEC "Enter URL" "Write the URL" || ft_exit 38
		[[ "${EXEC}" == "http"* ]] && EXEC="xdg-open ${EXEC}" || EXEC="xdg-open https://${EXEC}"
	fi
	if [[ "${ASK_TYPE}" == "Directory" ]];then
		EXEC=$(zenity --file-selection --directory --title="Select or Create the directory that will contains your launchers") && EXEC="xdg-open ${EXEC}" || ft_exit 39
	fi

	# -[ CREATE FOLDER ]-----------------------------------------------------------------------
	ft_echo -ne "\nCreate Folder:\n\t- "
	[[ ${VERBOSE} -eq 0 ]] && mkdir -p "${FOLDER_PATH}${FOLDER_NAME}/" || mkdir -p "${FOLDER_PATH}${FOLDER_NAME}/" -v

	#-[ CREATE ICON ]--------------------------------------------------------------------------
	select_image                                                # Ask to select an image or choose the one by default : DEFINE IMAGE_PATH
	ft_echo -e "\nCreate Icon:"                                 # Create Icon if non default icon used
	create_icon
	[[ -f ${iconFullName} ]] && ft_echo -e "\t- convert: create an icon '${iconFullName}'" || ft_exit 20

	# -[ CREATE FILE.DESKTOP ]------------------------------------------------------------------
	# Create file.desktop
	FILE="${FOLDER_PATH}${FOLDER_NAME}/${FOLDER_NAME}.desktop"
	ft_echo -e "\nCreate Desktop File:"
	touch ${FILE}                                               # Create {FILE}
	ft_echo -e "\t- Create ${FILE}:"
	echo "[Desktop Entry]" >> ${FILE}                           # ADD header
	echo "Type=Application" >> ${FILE}                          # ADD Type
	echo "Name=${FOLDER_NAME}" >> ${FILE}                       # ADD Name
	[[ -n ${COMMENT} ]] && echo "Comment=${COMMENT}" >> ${FILE} # ADD Description if not empty
	echo "Icon=${iconFullName}" >> ${FILE}                      # ADD Icon
	echo "Exec=sh -c \"${EXEC}\"" >> ${FILE}                    # ADD Exec
	[[ -n ${TERM} ]] && echo "Terminal=${TERM}" >> ${FILE}      # ADD Execution in a Terminal if it's an application

	# -[ UPDATE DATABASE ]--------------------------------------------------------------------------
	ft_echo -e "\nUpdate Desktop Database:\n\t- sudo update-desktop-database\n\t"
	sudo -n true > /dev/null 2>&1 || ft_echo -e "Enter your password in order to update your desktop database (this will make your new icon visible in your menu)"
	sudo update-desktop-database ${FOLDER_PATH}                         
fi 
