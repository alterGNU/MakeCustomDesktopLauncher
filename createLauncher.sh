#!/bin/bash

# ==================================================================================================
# CREATELAUNCHER.SH
# ==================================================================================================

# =[ ERRORS ]=======================================================================================
# ERROR10 => cleanup fct         : something goes wrong and cleanup function was called
# ERROR11 => checkPackage fct    : invalid number of arguments of check_package function
# ERROR12 => checkPackage fct    : a command is not install and user does not want to install it

# =[ SETTINGS ]=====================================================================================
set -euo pipefail                # Stop qd cmd or pipe fail or if undefined variable is used
trap cleanup 1 2 3 6 ERR         # Lance cleanup quand POSIX 1,2,3,6 ou quand script se stop

# =[ VARIABLES ]====================================================================================
SLPWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd) # Script Localisation and new PWD
folderPath="${HOME}/.local/share/applications/"                  # Where to create the folder
folderName=""

# =[ FUNCTIONS ]====================================================================================
# -[ CLEANUP ]--------------------------------------------------------------------------------------
function cleanup()
{
    echo -e "\nSomething goes wrong => CLEANING UP"
    if [[ -n ${folderName} && -d ${folderPath}${folderName} ]];then
        echo -e "removing ${folderPath}${folderName} folder"
        rm -vrf ${folderPath}${folderName}
    fi
    exit 10
}

# -[ CHECK FOLDER BY DEFAULT XDG ]------------------------------------------------------------------
function check_xdg()
{
    # ASK user where to store our desktop file if ~/.local/share/applications doesn't exist
    [[ -d ${folderPath}${folderName} ]] || mkdir -p ${folderPath}${folderName}
}

# -[ CHECK REQUIREMENT PACKAGES ]-------------------------------------------------------------------
function checkPackage()
{
    [[ $# -lt 1 || $# -gt 2 ]] && { echo -e "ERROR12: checkPackage() call failed, take 1 or 2 arguments." ; return 11 ; }
    cmd=$1
    [[ $# -eq 2 ]] && package=$2 || package=$1
    if ! which $1 > /dev/null;then
        echo -e "Command ${cmd} not found!Do you want to install ${package} with apt cmd?(y/n) \n"
        read
        if [ ${REPLY} == "y" ];then
            sudo apt install $package
        else
            echo -e "Unfortunately, since ${package} is required to use this script and you don't want to install it, this script will stop here. :'("
	    return 12
        fi
    else
        echo -e " - ${cmd}..OK! ${package} is installed"
    fi
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
