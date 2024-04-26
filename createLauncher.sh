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
set -euo pipefail                      # Stop when cmd or pipe fail or if undefined variable is used
trap cleanup 1 2 3 6 ERR               # Exec cleanup whne POSIX 1,2,3,6 or when script stop:ERR

# =[ VARIABLES ]====================================================================================
SLPWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)  # Script Localisation and new PWD
FOLDER_PATH="${HOME}/.local/share/applications/"                  # Where to create the folder
FOLDER_NAME=""
EXEC="" 

# =[ FUNCTIONS ]====================================================================================
# -[ CLEANUP ]--------------------------------------------------------------------------------------
function cleanup()
{
    # Call when something goes wrong, then clean the mess by removing our folder if created
    echo -e "\nSomething goes wrong => CLEANING UP"
    if [[ -n ${FOLDER_NAME} && -d ${FOLDER_PATH}${FOLDER_NAME} ]]; then
        rm -vrf "${FOLDER_PATH}${FOLDER_NAME}"
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
    tmp_value=$(zenity --entry --title="${title}" --text="${text}")
    eval ${1}=\"${tmp_value}\"
}

# -[ CHECK REQUIREMENT PACKAGES ]-------------------------------------------------------------------
function check_function_from_package()
{
    # 'check_function_from_package [function] [package]` check if a fonction from a package is install, else ask 
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
    #Resize the ${IMAGE_PATH} to a square images of 512*512 max, then add executable permissions as this icon will be use as a launcher.
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
    chmod +x ${iconFullName}
}

# -[ CREATE IMAGE ]---------------------------------------------------------------------------------
function select_image()
{
    #Ask if user want an image by default or a particular one(only JPEG, XPM, SVG and PNG formats)
    question="Do you want to use a particular icon for this shortcut or do you want to use the default icons?"
    spe_icon=$(zenity --list --title="Particular or Default Icon:" --text "${question}" --column "Answers" "Default Icon" "Search this PC for a particular image.")
    if [[ "${spe_icon}" == "Default Icon" ]];then
        [[ "${ASK_TYPE}" == "Directory" ]] && IMAGE_PATH="${SLPWD}/Icons/dirIcon.png"
        [[ "${ASK_TYPE}" == "Link" ]] && IMAGE_PATH="${SLPWD}/Icons/linkIcon.png"
        [[ "${ASK_TYPE}" == "Application" ]] && IMAGE_PATH="${SLPWD}/Icons/appIcon.png"
    else
        # ask for a path to an image that can be used as an icon until it is
        image_format=''
        while ([ "${image_format}" == "" ] || ([ "${image_format}" != "JPEG" ] && [ "${image_format}" != "XPM" ] && [ "${image_format}" != "SVG" ] && [ "${image_format}" != "PNG" ]));do 
            IMAGE_PATH=$(zenity --file-selection --title="Selectionner l'icône de l'application" --filename=/home/)
            image_format=$(identify -format '%m' ${IMAGE_PATH})
        done
    fi
}

# -[ CHECK FOLDER BY DEFAULT XDG ]------------------------------------------------------------------
function check_default_xdg()
{
	# ASK user where to store our desktop file if ~/.local/share/applications doesn't exist
	if [[ -d ${FOLDER_PATH} ]]; then
		echo -e "\t- '${FOLDER_PATH}' exist."
	else
		FOLDER_PATH=$(zenity --file-selection --directory --title="Select or Create the directory that will contains your launchers")
	fi
}

# -[ GET EXEC VALUE WHEN APPLICATION ] -------------------------------------------------------------
function get_exec_if_application()
{
    # If ask_type is an application, this function will ask to choose between a command line to execute or a script to launch.
    appOrCmd=$(zenity --list --title="Your application launch a Programm or execute a Command?" --column="Two choices:" "Browse folders for the executable" "Write the command line to run")
    while [ "${EXEC}" = "" ];do 
        if [[ "${appOrCmd}" == "Browse folders for the executable" ]];then
            EXEC=$(zenity --file-selection --title="Browse folders for the executable" --filename=${HOME}/) 
        else
	    get_value_from_user EXEC "Write the command line to run" "Write the command line to run"
	    EXEC="sh -c ${EXEC}"
        fi
    done
}

# ==================================================================================================
# MAIN
# ==================================================================================================

# -[ CHECK PACKAGES NEEDED ]------------------------------------------------------------------------
echo -e "Check Requirements Packages:"
check_function_from_package xdg-open xdg-utils                           # CheckIf xdg-open cmd from xdg-utils package is available
check_function_from_package zenity                                       # CheckIf zenity cmd is available 
check_function_from_package identify imagemagick                         # CheckIf identify cmd from imagemagick package is available
check_function_from_package convert imagemagick                          # CheckIf convert cmd from imagemagick package is available
check_function_from_package xdg-open xdg-utils                           # CheckIf xdg-command cmd from xdg-utils package is available
check_function_from_package update-desktop-database desktop-file-utils   # CheckIf package dekstop-file-utils is available

# -[ CHECK DEFAULT XDG FOLDER ]---------------------------------------------------------------------
echo -e "\nCheck Default Folder Localisation:"
check_default_xdg                                                        # CheckIf XDG default folder exist, else ask user to define one

# -[ GET INFORMATIONS FROM USER ]-------------------------------------------------------------------
# Ask a launcher/folder name while it's empty or folder's name already taken
while [ -d "${FOLDER_PATH}${FOLDER_NAME}" ] || [ -z "${FOLDER_NAME}" ] ;do
    get_value_from_user "FOLDER_NAME" "Choose launcher's name" "Please, enter the name of your launcher"
done
FOLDER_NAME=${FOLDER_NAME//\ /_}                                         # Replace spaces by underscores in folder's name

# Ask for a description
get_value_from_user comment "(OPTIONNAL):ADD some comment" "Tooltip for the entry, for example 'View sites on the Internet'."

# Ask to choose between Types                                            # ADD type
ASK_TYPE=$(zenity --list --title="Select the Type" --text "You want to create a launcher for:" --column "Answers" "Application" "Link" "Directory")

# Ask to select an image or choose the one by default : DEFINE IMAGE_PATH
select_image

# Ask the type : DEFINE EXEC
[[ "${ASK_TYPE}" == "Application" ]] && get_exec_if_application
[[ "${ASK_TYPE}" == "Link" ]] && get_value_from_user EXEC "Enter URL" "Write the URL" && EXEC="xdg-open ${EXEC}"
[[ "${ASK_TYPE}" == "Directory" ]] && EXEC=$(zenity --file-selection --directory --title="Select or Create the directory that will contains your launchers") && EXEC="xdg-open ${EXEC}"

# -[ CREATE FOLDER ]--------------------------------------------------------------------------------
echo -ne "\nCreate Folder:\n\t- "
mkdir -p "${FOLDER_PATH}${FOLDER_NAME}/" -v

# -[ CREATE ICON ]----------------------------------------------------------------------------------
# Create Icon if non default icon used
echo -e "\nCreate Icon:"
create_icon
[[ -f ${iconFullName} ]] && echo "convert: create an icon '${iconFullName}'" || { echo "ERROR13: No icon was created" ; exit 13 ; }

# -[ CREATE FILE.DESKTOP ]--------------------------------------------------------------------------
# Create file.desktop
FILE="${FOLDER_PATH}${FOLDER_NAME}/${FOLDER_NAME}.desktop"
echo -e "\nCreate ${FILE}:"
touch ${FILE}                                                           # Create {FILE}
echo "[Desktop Entry]" >> ${FILE}                                       # ADD header
echo "Type=Application" >> ${FILE}                                      # ADD Type
echo "Name=${FOLDER_NAME}" >> ${FILE}                                   # ADD Name
echo "Comment=${comment}" >> ${FILE}                                    # ADD Description
echo "Icon=${iconFullName}" >> ${FILE}                                  # ADD Icon
echo "Exec=sh -c \"${EXEC}\"" >> ${FILE}                                # ADD Exec

# Update database of desktop entries
#sudo desktop-file-install ${FOLDER_PATH} #May be usefull if FOLDER_PATH != ~/.local/share/application
sudo update-desktop-database ${FOLDER_PATH}
