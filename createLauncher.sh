#!/bin/bash
 
# ==================================================================================================
# CREATELAUNCHER.SH
# ==================================================================================================

# =[ ERRORS ]=======================================================================================
# ERROR11 => cleanup             : something goes wrong and cleanup function was called
# ERROR12 => checkPackage        : invalid number of arguments
# ERROR13 => createIcon          : no icon converted in folder

# =[ SETTINGS ]=====================================================================================
trap cleanup 1 2 3 6

# =[ VARIABLES ]====================================================================================
localisation=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
folderPath="${HOME}/.local/share/applications/"
folderName=""
imagePath=""
iconFullName=""
link=""
execAppOrCmd=""

# =[ FUNCTIONS ]====================================================================================
# -[ CLEANUP ]--------------------------------------------------------------------------------------
function cleanup(){
    echo -e "\nSomething goes wrong!"
    if [ "${folderName}" != "" ];then
        echo -e "removing ${folderPath}${folderName} folder"
        rm -rf ${folderPath}${folderName}
    fi
    exit 11
}

# -[ CALL CLEANUP AND EXIT ]------------------------------------------------------------------------
function killIfLastCmdFailed(){ [[ ${?} -ne 0 ]] && kill -s SIGINT ${$} ; }

# -[ CHECK REQUIREMENT PACKAGES ]-------------------------------------------------------------------
function checkPackage(){
    [[ $# -lt 1 || $# -gt 2 ]] && { echo -e "ERROR12: checkPackage() call failed, take 1 or 2 arguments." ; exit 12 ; }
    cmd=$1
    [[ -z $2 ]] && package=$1 || package=$2
    if ! which $1 > /dev/null;then
        echo -e "Command ${cmd} not found!Do you want to install ${package} with apt cmd?(y/n) \n"
        read
        if [ ${REPLY} == "y" ];then
            sudo apt install $package
        else
            echo -e "Unfortunately, since ${package} is required to use this script and you don't want to install it, this script will stop here.:'("
        fi
    else
        echo -e " - ${cmd}..OK! ${package} is installed"
    fi
}
 
# -[ ASK USER FOLDER'S NAME ]-----------------------------------------------------------------------
function askName(){
    name=$(zenity --entry --title="Creating the launcher" --text="Enter the name of the application")
    killIfLastCmdFailed
    compliantName=$(echo "${name//[!a-zA-Z0-9]/}")
    echo ${compliantName}
}

# -[ SELECT IMAGE ]---------------------------------------------------------------------------------
function selectImage(){
    imagePath=$(zenity --file-selection --title="Selectionner l'icône de l'application" --filename=/home/)
    killIfLastCmdFailed
    imagePath=$(sed "s/\ /\\\ /g" <<< ${imagePath})
    echo ${imagePath}
}

# -[ CHECK IMAGE EXTENSION ]------------------------------------------------------------------------
function isNotASupportedFormat(){
    if eval identify ${@} &> /dev/null ;then
        ext=$(eval identify -format '%m' ${@})
        if [ "${ext}" = "JPEG" ] || [ "${ext}" = "XPM" ] || [ "${ext}" = "SVG" ] || [ "${ext}" = "PNG" ];then
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

# -[ CREATE ICON ]----------------------------------------------------------------------------------
function createIcon(){
    long=$(eval identify -format '%W' ${imagePath})
    larg=$(eval identify -format '%H' ${imagePath})
    iconPath="${folderPath}${folderName}/"
    if [ ${long} -gt 512 ] && [ ${larg} -gt 512 ];then
        iconFormat=512x512
        iconName="${folderName}_512x512.png"
    elif [ ${long} -lt ${larg} ];then
        iconFormat=${long}x${long}
        iconName="${folderName}_${long}x${long}.png"
    else
        iconFormat=${larg}x${larg}
        iconName="${folderName}_${larg}x${larg}.png"
    fi
    iconFullName=${iconPath}${iconName}
    eval convert ${imagePath} -resize ${iconFormat}! ${iconFullName}
    eval chmod +x ${iconFullName}
}

# ==================================================================================================
# MAIN
# ==================================================================================================

# -[ CHECKS ]---------------------------------------------------------------------------------------
echo -e "Check Requirements Packages:"
checkPackage xdg-open xdg-utils   # CheckIf xdg-open cmd from xdg-utils package is available
checkPackage zenity               # CheckIf zenity cmd is available
checkPackage identify imagemagick # CheckIf convert cmd from imagemagick package is available
checkPackage convert imagemagick  # CheckIf convert cmd from imagemagick package is available

# -[ CREATE FOLDER ]--------------------------------------------------------------------------------
echo -e "\nCreate Folder:"
# ask a folder name while it's is empty or already taken
while [ -e "${folderPath}${folderName}" ] || [ "${folderName}" == "" ] ;do folderName=$(askName);done
mkdir -p "${folderPath}${folderName}/" -v


# -[ CREATE FILE.DESKTOP ]--------------------------------------------------------------------------
echo -e "\nCreate Desktop file:"
# Create file
file="${folderPath}${folderName}/${folderName}.desktop"
touch $file
echo "touch: create desktop file '${file}'"

# Add HEADER
[[ "${XDG_CURRENT_DESKTOP}" =~ "GNOME" ]] && echo "[Desktop Entry]" >> $file || echo "[KDE Desktop Entry]" >> $file

# Ask to choose between Types
linkType=$(zenity --list --title="Select the Type" --text "You want to create a(n):" --radiolist --column "Pick" --column "Answer" TRUE "Application launcher" FALSE "Web Link" FALSE "Directory Link")
killIfLastCmdFailed
echo "Type=Application" >> $file

# Add Name
echo "Name=${folderName}" >> $file

# Ask for comment (OPT)
comment=$(zenity --entry --title="(OPTIONNAL):ADD some comment" --text="Tooltip for the entry, for example 'View sites on the Internet'.")
killIfLastCmdFailed
[[ ${comment} != "" ]] && echo "Comment=${comment}" >> $file

# Convert image->icon
if [[ "${linkType}" != "Application launcher" ]];then
    question="Do you want to use a particular icon for this shortcut or do you want to use the default icons?"
    speIcon=$(zenity --list --title="Particular or Default Icon:" --text "${question}" --radiolist --column "Pick" --column "Answer" TRUE "Default Icon" FALSE "Search this PC for a particular image.")
    killIfLastCmdFailed
    if [[ "${speIcon}" == "Default Icon" ]];then
    [[ "${linkType}" == "Web Link" ]] && imagePath="${localisation}/webIcon.png" || imagePath="${localisation}/folderIcon.png"
    else
        # ask for a path to an image that can be used as an icon until it is
        while [ "${imagePath}" == "" ] || isNotASupportedFormat ${imagePath};do imagePath=$(selectImage);done
    fi
else
    # ask for a path to an image that can be used as an icon until it is
    while [ "${imagePath}" == "" ] || isNotASupportedFormat ${imagePath};do imagePath=$(selectImage);done
    echo -e "\nCreate Icon:"
fi
createIcon
[[ -f ${iconFullName} ]] && echo "convert: create an icon '${iconFullName}'" || { echo "ERROR13: No icon was created" ; exit 13 ; }
echo "Icon=${iconFullName}" >> $file

# Ask for exec:
if [[ "${linkType}" == "Web Link" ]];then
    link=$(zenity --entry --title="Create a web-link using URL" --text="Paste your URL here")
    killIfLastCmdFailed
elif [[ "${linkType}" == "Directory Link" ]];then
    link=$(zenity --file-selection --title="Create folder link by selecting one" --filename=${HOME}/ --directory)
    killIfLastCmdFailed
else
    appOrCmd=$(zenity --list --title="Your application will launch a Programm or it'll execute a Command" --column="Two choices:" "Browse folders for the executable" "Write the command line to run")
    killIfLastCmdFailed
    while [ "${execAppOrCmd}" == "" ];do 
        if [[ "${appOrCmd}" == "Browse folders for the executable" ]];then
            execAppOrCmd=$(zenity --file-selection --title="Browse folders for the executable" --filename=${HOME}/) 
        else
            execAppOrCmd=$(zenity --entry --title="Write the command line to run" --text="Write the command line to run")
        killIfLastCmdFailed ;
        fi
    done
fi

[[ "${link}" != "" ]] && echo "Exec=sh -c \"xdg-open '${link}'\"" >> $file
[[ "${execAppOrCmd}" != "" ]] && echo "Exec=sh -c \"${execAppOrCmd}\"" >> $file

# Si gnome, restart poour afficher l'icone
[[ "${XDG_CURRENT_DESKTOP}" =~ "GNOME" ]] && busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting Gnome…")'

exit 0
