# MakeCustomDesktopLauncher
This BashScript create a custom launcher for any app, command line, link to a website or to a folder.

## Installation
Just clone the repo
```bash
git clone https://github.com/alterGNU/MakeCustomDesktopLauncher.git
```

## Requirements
Desktop File are only used by Linux operating systems and both KDE and GNOME desktop environments have adopted this format: file.desktop.
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
	cd MakeCustomDesktopLauncher && ./createLauncher.sh
	```
- 4 : Once this step is completed, a .desktop file as well as an icon are created.
    - To ensure the shortcut appears in the menu, the script will end by running the command `update-desktop-database` as a superuser.
    - Therefore, you will need to enter your user password and then enjoy your new launcher ;)

### EX1 : Create Applications Launcher
- 1 : First Example is an application run with a script, in a terminal and with default icon: MCDL (it will be used to create the second example)
- 2 : Second Example is an application run with a command, not in a terminal and with a custom icon: gnome-terminal

![AppExamples](https://github.com/alterGNU42/DATA/blob/main/MakeCustomDesktopLauncher/GIFs/applications.gif)

### EX2 : Create Folders Shortcut
- 1 : First Example shortcut to Home Folder with the default icon.
- 2 : Second Example shortcut to Videos Folder with a custom icon.

![FoldersExamples](https://github.com/alterGNU42/DATA/blob/main/MakeCustomDesktopLauncher/GIFs/folders.gif)

### EX3 : Create Web Links
- 1 : First Example link to google.com with default web icon.
- 2 : Second Example link to https://github.com/alterGNU42/ with custom icon.

![LinksExamples](https://github.com/alterGNU42/DATA/blob/main/MakeCustomDesktopLauncher/GIFs/links.gif)

--- 

# TODO-LIST
- [ ] Utiliser MCDL pour installer MCDL
- [ ] Tester sur autres Environnements (voir DOCKER)
	- [ ] Tester cas ou pas de ~/.local/share/application/ (=> choix dossier par user, verifier fonctionnement de la commande update-desktop-data suffit)
## Enhancement
- [ ] ADD Option : quand LINK && Google-chrome = Script creant automatiquement un lanceur pour chaque comptes utilise
	- [ ] ADD Option special pour Google-Chrome-Account permettant de lancer ce script
	- [ ] ADD Command permettant de cree des images propres a chaque compte au lancement [voir](https://stackoverflow.com/questions/20075087/how-to-merge-images-in-command-line)
- [ ] ADD cases : function check_function_from_package use `apt` to install, test and add if apt not used in other/or/same distros (test with DOCKER)
- [ ] ADD Arguments au script : 
	- [ ] -h/--help : Affiche l'aide de la commande/script
	- [X] Rendre le script silencieux par default
	- [X] -v/--verbose : Le rendre tchatti
	- [ ] -l/--list : List dans une fenetre les desktops files deja cree(Dossier contenant une image et un file.desktop)
	- [ ] -r/--remove : List dans une fenetre les desktops files deja cree et permet en les selectionnants de les supprimers
- [ ] Transformer en commande (PATH)
## Bugs/Problems
- [ ] Fenetre de la mauvaise taille a l'ouverture
- [ ] bouttons cancel et exit
	- [ ] Fenetre Application>fct get_exec_if_application et les suivantes
	- [ ] Fenetre Link>...toutes... cad select_image et create_icon
	- [ ] Fenetre Directories>...toutes... cad select_image et create_icon
## Questions
- [ ] Comment ajouter en entree a la commande man?
