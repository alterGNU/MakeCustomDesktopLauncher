#!/bin/bash

# ==================================================================================================
# CREATELAUNCHER.SH
# ==================================================================================================

# =[ ERRORS ]=======================================================================================
# ERROR10 => cleanup fct         : something goes wrong and cleanup function was called

# =[ SETTINGS ]=====================================================================================
set -e                           # Stop le script lorsqu'une de ses commandes fail
trap cleanup 1 2 3 6 ERR         # Lance cleanup quand POSIX 1,2,3,6 ou quand script se stop

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
function cleanup()
{
    echo -e "\nSomething goes wrong => CLEANING UP"
    rm -rf "${localisation}/toto"
    if [ "${folderName}" != "" ];then
        echo -e "removing ${folderPath}${folderName} folder"
	rmdir toto
        #rm -rf ${folderPath}${folderName}
    fi
    exit 10
}

function testo()
{
	mkdir
}

# ==================================================================================================
# MAIN
# ==================================================================================================
mkdir
