#!/bin/bash
# Installer for guru-client. ujo.guru casa@ujo.guru 2017-2020

GURU_CALL="guru"                                                # default environment variables for installer
GURU_USER="$USER"
GURU_BIN=$HOME/bin
GURU_CFG=$HOME/.config/guru

source src/deco.sh                                          # include decorative functions
source src/os.sh                                            # include os functions
source src/keyboard.sh                                          # include keyboard functions

target_rc="$HOME/.bashrc"                                       # environmental values rc file
disabler_flag_file="$HOME/.gururc.disabled"                     # flag for disabling the rc file

TEMP=`getopt --long -o "fu:" "$@"`
eval set -- "$TEMP"
while true ; do
    case "$1" in
        -f ) export force_overwrite=true ; shift ;;
        -u ) export GURU_USER=$2         ; shift 2 ;;
         * ) break
    esac
done;
_arg="$@"
[[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"

# main command parser                                           # TODO - re-write whole installer, this is bullshit
case "$1" in
       help)    echo "-- guru-client istall help -----------------------------------------------"
                printf "\nUsage:\n\t ./install.sh [argument] \n"
                printf "\nArguments:\n\n"
                printf " force             force re-install \n"
                printf " desktop           desktop install for [ubuntu 18.04>, mint 19.1>19.3]\n"
                printf " headless          server install [tested in_ubuntu server 18.04>] \n\n"
                ;;
esac

# check is it currently installed
if grep -q ".gururc" "$target_rc" ; then                                                            # already installed? reinstall?
    [[ $force_overwrite ]] && answer="y" ||read -p "already installed, force re-install [y/n] : " answer

    if ! [[ "$answer" == "y" ]]; then
        echo "aborting.."
        exit 2
    fi

    [[ -f "$GURU_BIN/uninstall.sh" ]] && bash "$GURU_BIN/uninstall.sh" || echo "un-installer not found"
fi

# Make a backup of original .bashrc only if installed first time
[[ -f "$HOME/.bashrc.giobackup" ]] || cp -f "$target_rc" "$HOME/.bashrc.giobackup"                  # todo: better method -> add lines to .bashrc file, uninstaller removes added lines
grep -q ".gururc" "$target_rc" || cat ./src/tobashrc.sh >>"$target_rc"                              # Check is .gururc called from .bashrc, add call if not

[[ -f "$disabler_flag_file" ]] && rm -f "$disabler_flag_file"                                       # todo: remove disabler function

# create folder structure
cp -f ./src/gururc.sh "$HOME/.gururc"                                                               # todo: user settings should be exported from default user.cfg not like this (stupid)
source "$HOME/.gururc"                                                                              # rise default environmental variables

[[ -d "$GURU_BIN" ]] || mkdir -p "$GURU_BIN"                                                        # make bin folder for script files
[[ -d "$GURU_CFG" ]] || mkdir -p "$GURU_CFG"                                                        # make cfg folder for configuration files
[[ -d "$GURU_APP" ]] || mkdir -p "$GURU_APP"                                                        # todo: remove app folder, not really in use
[[ -d "$GURU_CFG/$GURU_USER" ]] || mkdir -p "$GURU_CFG/$GURU_USER"                                  # personal configurations

cp -f ./cfg/* "$GURU_CFG"                                                                           # copy configuration files to configuration folder
cp -f -r ./src/* -f "$GURU_BIN"                                                                     # copy script files to bin folder
mv  "$GURU_BIN/guru.sh" "$GURU_BIN/guru"                                                            # rename guru.sh in bin folder to guru

if ! dpkg -l | grep xserver-xorg >/dev/null ; then                                                 # End here if no X installed
        echo "headless client successfully installed"
        exit 0
    fi

platform=$(check_distro)                                                                            # check that distribution is compatible
case "$platform" in                                                                                 # different dependent settings

    debian)
        case "$NAME" in
            devuan*)
                    exit 0                                                                          # nothing to do for now
                    ;;
                  *)                                                                                # debian based other thing
            esac
        ;;

    linuxmint)
        cinnamon_version=$(cinnamon --version |grep -o "[^ ]*$"|cut -f1 -d".")                      # check cinnamon main version number
        if [ "$cinnamon_version" -lt "4" ]; then                                                    # compatible with cinnamon version 3+
            echo "not valid version of cinnamon environment, exiting.."
            exit 2
        else                                                                                        # Install cinnamon tools
            dconf help >/dev/null || sudo apt install dconf-cli                                     # check that cinnamon setting tools is installed
            [[ -f /usr/bin/xclip ]] || sudo apt install xclip
            xterm -v >/dev/null || sudo apt install xterm                                           # check that xterm is installed
        fi
        keyboard.set_cinnamon_guru_shortcuts                                                        # add keyboard sort cuts for cinnamon
        ;;

    ubuntu)
        gnome_version=$(gnome-shell --version |grep -o "[^ ]*$"|cut -f1 -d".")                      # check gnome main version  number

        if [ "$gnome_version" -lt "3" ]; then                                                       # compatible with gnome version 3+
            echo "not valid version of gnome environment, exiting.."
            exit 2
        else                                                                                        # Install gnome tools
            dconf help >/dev/null || sudo apt install dconf-cli                                     # check that gnome setting tools is installed
            [[ -f /usr/bin/xclip ]] || sudo apt install xclip
            xterm -v >/dev/null || sudo apt install xterm                                           # check that xterm is installed
        fi
        keyboard.set_ubuntu_guru_shortcuts                                                          # add keyboard sort cuts for ubuntu
        ;;

    *)
        echo "non valid platform $platform"                                                         # if returns something else
        exit 4
esac

echo "$(guru version) installed"                                                                       # all fine
exit 0







