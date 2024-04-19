#!/bin/bash

# ==================================================================================================
# CREATELAUNCHER.SH
# ==================================================================================================

# =[ ERRORS ]=======================================================================================
# ERROR10 => cleanup fct         : something goes wrong and cleanup function was called
# ERROR11 => check_package fct   : invalid number of arguments of check_package function
# ERROR12 => check_package fct   : a command is not install and user does not want to install it
# ERROR13 => get_value_from_user : invalid number of arguments of get_value_from_user function

# =[ SETTINGS ]=====================================================================================
set -euo pipefail                # Stop when cmd or pipe fail or if undefined variable is used
trap cleanup 1 2 3 6 ERR         # Exec cleanup whne POSIX 1,2,3,6 or when script stop:ERR

# =[ VARIABLES ]====================================================================================
SLPWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd) # Script Localisation and new PWD
folderPath="${HOME}/.local/share/applications/"                  # Where to create the folder
folderName=""

# =[ FUNCTIONS ]====================================================================================
# -[ CLEANUP ]--------------------------------------------------------------------------------------
function cleanup()
{
    echo -e "\nSomething goes wrong => CLEANING UP"
    if [[ -n ${folderName} && -d ${folderPath}${folderName} ]]; then
        echo -e "removing ${folderPath}${folderName} folder"
        rm -vrf ${folderPath}${folderName}
    fi
    exit 10
}

# -[ GET VALUE FROM USER]---------------------------------------------------------------------------
function get_value_from_user()
{
	# `get_value_form_user arg1` Ask user the value of the variable ${arg1} then update it value.
	[[ ${#} -lt 1 || ${#} -gt 3 ]] && { echo -e "ERROR13: get_value_from_user() call failed, take 1,2 or 3 arguments : (usage) get_value_from_user variable_name title_message text_message." ; return 13 ; }
	[[ ${#} -gt 1 ]] && local title=${2} || local title="Change the value of \${${1}}"
	[[ ${#} -gt 2 ]] && local text=${3} || local text="Enter the value of the variable \${${1}}"
    eval ${1}=$(zenity --entry --title="${title}" --text="${text}")
}

# -[ CHECK REQUIREMENT PACKAGES ]-------------------------------------------------------------------
function checkPackage()
{
    [[ $# -lt 1 || $# -gt 2 ]] && { echo -e "ERROR12: checkPackage() call failed, take 1 or 2 arguments." ; return 11 ; }
    cmd=$1
    [[ $# -eq 2 ]] && package=$2 || package=$1
    if ! which $1 > /dev/null; then
        echo -e "Command ${cmd} not found!Do you want to install ${package} with apt cmd?(y/n) \n"
        read
        if [ ${REPLY} == "y" ]; then
            sudo apt install $package
        else
            echo -e "Unfortunately, since ${package} is required to use this script and you don't want to install it, this script will stop here. :'("
	    return 12
        fi
    else
        echo -e "\t- ${cmd} is installed."
    fi
}

# -[ CHECK FOLDER BY DEFAULT XDG ]------------------------------------------------------------------
function check_default_xdg()
{
	# ASK user where to store our desktop file if ~/.local/share/applications doesn't exist
	if [[ -d ${folderPath} ]]; then
		echo -e "\t- '${folderPath}' exist."
	else
		folderPath=$(zenity --file-selection --directory --title="Select or Create the directory that will contains your launchers")
	fi
}


# ==================================================================================================
# MAIN
# ==================================================================================================

# -[ CHECK PACKAGES NEEDED ]------------------------------------------------------------------------
echo -e "Check Requirements Packages:"
checkPackage xdg-open xdg-utils   # CheckIf xdg-open cmd from xdg-utils package is available
checkPackage zenity               # CheckIf zenity cmd is available
checkPackage identify imagemagick # CheckIf convert cmd from imagemagick package is available
checkPackage convert imagemagick  # CheckIf convert cmd from imagemagick package is available

# -[ CHECK DEFAULT XDG FOLDER ]---------------------------------------------------------------------
echo -e "\nCheck Default Folder Localisation:"
check_default_xdg                 # CheckIf XDG default folder exist, else ask user to define one

# -[ CREATE FOLDER ]--------------------------------------------------------------------------------
echo -e "\nCreate Folder:"
# ask a folder name while it's empty or already taken
while [ -d "${folderPath}${folderName}" ] || [ -z "${folderName}" ] ;do get_value_from_user folderName "Choose launcher's name" "Please, enter the name of your launcher";done
echo -ne "\t- "
mkdir -vp "${folderPath}${folderName}/"
