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
SLPWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)  # Script Localisation and new PWD
folder_path="${HOME}/.local/share/applications/"                  # Where to create the folder
folder_name=""
EXEC="" 

# =[ FUNCTIONS ]====================================================================================
# -[ CLEANUP ]--------------------------------------------------------------------------------------
function cleanup()
{
    echo -e "\nSomething goes wrong => CLEANING UP"
    if [[ -n ${folder_name} && -d ${folder_path}${folder_name} ]]; then
        echo -e "removing ${folder_path}${folder_name} folder"
        rm -vrf "${folder_path}${folder_name}"
    fi
    exit 10
}

# -[ GET VALUE FROM USER]---------------------------------------------------------------------------
function get_value_from_user()
{
    # `get_value_form_user arg1` Ask user the value of the variable ${arg1} then update it value.
    [[ ${#} -lt 1 || ${#} -gt 3 ]] && { echo -e "ERROR13: get_value_from_user() call failed, take 1,2 or 3 arguments : (usage) get_value_from_user variable_name title_message text_message." ; return 13 ; }
    [[ ${#} -gt 1 ]] && local title=${2} || local title="Change the value of \${${1}}"
    [[ ${#} -gt 2 ]] && local text=${3} || local text="Enter the new value you want to assign to the variable \${${1}}"
    eval ${1}=\"$(zenity --entry --title="${title}" --text="${text}")\"
}

# -[ CHECK REQUIREMENT PACKAGES ]-------------------------------------------------------------------
function check_function_from_package()
{
    [[ $# -lt 1 || $# -gt 2 ]] && { echo -e "ERROR12: check_function_from_package() call failed, take 1 or 2 arguments." ; return 11 ; }
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

# -[ CREATE ICON ]----------------------------------------------------------------------------------
function create_icon()
{
    local long=$(identify -format '%W' ${image_path})
    local larg=$(identify -format '%H' ${image_path})
    local iconPath="${folder_path}${folder_name}/"
    if [ ${long} -gt 512 ] && [ ${larg} -gt 512 ];then
        local iconFormat=512x512
        local iconName="${folder_name}_512x512.png"
    elif [ ${long} -lt ${larg} ];then
        local iconFormat=${long}x${long}
        local iconName="${folder_name}_${long}x${long}.png"
    else
        local iconFormat=${larg}x${larg}
        local iconName="${folder_name}_${larg}x${larg}.png"
    fi
    iconFullName=${iconPath}${iconName}
    convert ${image_path} -resize ${iconFormat}! ${iconFullName}
    chmod +x ${iconFullName}
}

# -[ CHECK FOLDER BY DEFAULT XDG ]------------------------------------------------------------------
function check_default_xdg()
{
	# ASK user where to store our desktop file if ~/.local/share/applications doesn't exist
	if [[ -d ${folder_path} ]]; then
		echo -e "\t- '${folder_path}' exist."
	else
		folder_path=$(zenity --file-selection --directory --title="Select or Create the directory that will contains your launchers")
	fi
}

# -[ GET EXEC VALUE WHEN APPLICATION ] -------------------------------------------------------------
function get_exec_if_application()
{
    appOrCmd=$(zenity --list --title="Your application launch a Programm or execute a Command?" --column="Two choices:" "Browse folders for the executable" "Write the command line to run")
    while [ "${EXEC}" = "" ];do 
        if [[ "${appOrCmd}" = "Browse folders for the executable" ]];then
            EXEC=$(zenity --file-selection --title="Browse folders for the executable" --filename=${HOME}/) 
        else
	    get_value_from_user EXEC "Write the command line to run" "Write the command line to run"
        fi
    done
}

# -[ CREATE OTHER ]---------------------------------------------------------------------------------
function create_other()
{
	#Faire un questionnaire de jean-michel permettant de remplir chaque champs un a un + explication
	echo WORKINPROGRESS
}

# ==================================================================================================
# MAIN
# ==================================================================================================

# -[ CHECK PACKAGES NEEDED ]------------------------------------------------------------------------
echo -e "Check Requirements Packages:"
check_function_from_package xdg-open xdg-utils                           # CheckIf xdg-open cmd from xdg-utils package is available
check_function_from_package zenity                                       # CheckIf zenity cmd is available 
check_function_from_package identify imagemagick                         # CheckIf convert cmd from imagemagick package is available
check_function_from_package convert imagemagick                          # CheckIf convert cmd from imagemagick package is available
check_function_from_package identify imagemagick                         # CheckIf idnetify cmd from imagemagick package is available
check_function_from_package xdg-open xdg-utils                           # CheckIf xdg-command cmd from xdg-utils package is available
check_function_from_package update-desktop-database desktop-file-utils   # CheckIf package dekstop-file-utils is available

# -[ CHECK DEFAULT XDG FOLDER ]---------------------------------------------------------------------
echo -e "\nCheck Default Folder Localisation:"
check_default_xdg                                         # CheckIf XDG default folder exist, else ask user to define one

# -[ GET INFORMATIONS FROM USER ]-------------------------------------------------------------------
# ask a launcher/folder name while it's empty or folder's name already taken
while [ -d "${folder_path}${folder_name}" ] || [ -z "${folder_name}" ] ;do get_value_from_user "folder_name" "Choose launcher's name" "Please, enter the name of your launcher";done
folder_name=${folder_name//\ /_}

# ask for a description
get_value_from_user comment "(OPTIONNAL):ADD some comment" "Tooltip for the entry, for example 'View sites on the Internet'."

# -[ CREATE FOLDER ]--------------------------------------------------------------------------------
echo -ne "\nCreate Folder:\n\t- "
mkdir -p "${folder_path}${folder_name}/" -v

# -[ CREATE FILE.DESKTOP ]--------------------------------------------------------------------------
echo -e "\nCreate Desktop file:"

# Create file
file="${folder_path}${folder_name}/${folder_name}.desktop"
touch ${file}                                                           # Create {file}

# Ask to choose between Types                                           # ADD type
ask_type=$(zenity --list --title="Select the Type" --text "You want to create a launcher for:" --column "Answers" "Application" "Link" "Directory")

# -[ CREATE IMAGE ]---------------------------------------------------------------------------------
question="Do you want to use a particular icon for this shortcut or do you want to use the default icons?"
spe_icon=$(zenity --list --title="Particular or Default Icon:" --text "${question}" --column "Answers" "Default Icon" "Search this PC for a particular image.")
if [[ "${spe_icon}" == "Default Icon" ]];then
    [[ "${ask_type}" == "Directory" ]] && image_path="${SLPWD}/Icons/dirIcon.png"
    [[ "${ask_type}" == "Link" ]] && image_path="${SLPWD}/Icons/linkIcon.png"
    [[ "${ask_type}" == "Application" ]] && image_path="${SLPWD}/Icons/appIcon.png"
else
    # ask for a path to an image that can be used as an icon until it is
    image_format=''
    while ([ "${image_format}" == "" ] || ([ "${image_format}" != "JPEG" ] && [ "${image_format}" != "XPM" ] && [ "${image_format}" != "SVG" ] && [ "${image_format}" != "PNG" ]));do 
        image_path=$(zenity --file-selection --title="Selectionner l'icône de l'application" --filename=/home/)
        image_format=$(identify -format '%m' ${image_path})
    done
fi

# Create Icon if non default icon used
echo -e "\nCreate Icon:"
create_icon
[[ -f ${iconFullName} ]] && echo "convert: create an icon '${iconFullName}'" || { echo "ERROR13: No icon was created" ; exit 13 ; }

# -[ DEFINE EXEC ]----------------------------------------------------------------------------------
# Define Exec
[[ "${ask_type}" == "Application" ]] && get_exec_if_application && EXEC="sh -c ${EXEC}"
[[ "${ask_type}" == "Link" ]] && get_value_from_user EXEC "Enter URL" "Write the URL" && EXEC="xdg-open ${EXEC}"
[[ "${ask_type}" == "Directory" ]] && EXEC=$(zenity --file-selection --directory --title="Select or Create the directory that will contains your launchers") && EXEC="xdg-open ${EXEC}"

# Fill File
echo "[Desktop Entry]" >> ${file}                                       # ADD header
echo "Type=Application" >> ${file}                                      # ADD Type
echo "Name=${folder_name}" >> ${file}                                   # ADD Name
echo "Comment=${comment}" >> ${file}                                    # ADD Description
echo "Icon=${iconFullName}" >> $file                                    # ADD Icon
echo "Exec=sh -c \"${EXEC}\"" >> $file                                  # ADD Exec

# Update database of desktop entries
#sudo desktop-file-install ${folder_path}
sudo update-desktop-database ${folder_path}
