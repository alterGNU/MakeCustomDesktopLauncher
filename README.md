# MakeCustomDesktopLauncher
This BashScript create a custom launcher for any app, command line, link to a website or to a folder.

## Installation
Just clone the repo
```bash
git clone https://github.com/alterGNU/MakeCustomDesktopLauncher.git
```

## Requirements
_I'm using ubuntu 22.04.4 LTS (GNOME)_

### Packages (commands)
- The script will automatically check if thoses packages are installed:
	- xdg-utils : for `xdg-open` command.
	- zenity : for `zenity` command.
	- imagemagick : for `identify` and `convert` commands.
	- desktop-file-utils : for `update-desktop-database` command.
_I'm using ubuntu 22.04.4 LTS (GNOME)wich means that if a package is not installled, the script will prompt whether its installation is desired, then use `apt` command to do so if the user chooses_

## Usage
- 1 : get the executable, command or link you want to run
- 2 : get the image you want to turn into an icon (OPT)
- 3 : execute createLauncher.sh and follow the instructions ... :)
	```bash
	cd MakeCustomDesktopLauncher.git && ./createLauncher.sh
	```
- 4 : Once this step is completed, a .desktop file as well as an icon are created.
    - To ensure the shortcut appears in the menu, the script will end by running the command `update-desktop-database` as a superuser.
    - Therefore, you will need to enter your user password and then enjoy your new launcher ;)
