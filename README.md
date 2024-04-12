# MakeCustomDesktopLauncher
This BashScript allows you to create a custom launcher for any app, command or link (web or to folders).

## Installation
Just clone the repo
```bash
git clone https://github.com/alterGNU/MakeCustomDesktopLauncher.git
```

## Requirements
_I'm using ubuntu 22.04.4 LTS (GNOME)_

### Packages (commands)
- xdg-utils (for `wdg-open` command)
- zenity (for `zenity` command)
- imagemagick (for `identify` and `convert` commands)

## Usage
- 1 : get the executable, command or link you want to run
- 2 : get the image you want to turn into an icon
- 3 : execute createLauncher.sh and follow the instructions ... :)
	```bash
	cd MakeCustomDesktopLauncher.git && ./createLauncher.sh
	```
- 4 : Once done, you may need to restart gnome to see your launcher:
	- 4.1 : Open gnome prompt with `[Alt] + [F2]`
	- 4.2 : Restart gnome `[r]`
