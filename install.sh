#!/bin/bash
# Installer for guru tool-kit. ujo.guru casa@ujo.guru 2017-2020

GURU_CALL="guru"                                                # default environment variables for installer
GURU_USER="$USER"
GURU_BIN=$HOME/bin
GURU_CFG=$HOME/.config/guru

source src/lib/deco.sh                                          # include decorative functions
source src/lib/os.sh                                            # include os functions
source src/keyboard.sh                                          # include keyboard functions
source src/counter.sh                                           # include counter

target_rc="$HOME/.bashrc"                                       # environmental values rc file
disabler_flag_file="$HOME/.gururc.disabled"                     # flag for disabling the rc file


TEMP=`getopt --long -o "fu:" "$@"`
eval set -- "$TEMP"
while true ; do
    case "$1" in
        -f ) export force_overwrite=true ; shift ;;
        -u ) export GURU_USER=$2 ; shift 2 ;;
         * ) break                  ;;
    esac
done;
_arg="$@"
[[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"



case "$1" in                                                    # simple location pased argument parser
    help)
            echo "-- guru tool-kit istall help -----------------------------------------------"
            printf "\nUsage:\n\t ./install.sh [argument] \n"
            printf "\nArguments:\n\n"
            printf " force             force re-install \n"
            printf " desktop           desktop install for [ubuntu 18.04>, mint 19.1>19.3]\n"
            printf " server            server install [ubuntu server 18.04>] \n\n"
            ;;

esac

if grep -q ".gururc" "$target_rc" ; then                                                            # already installed? reinstall?
    [[ $force_overwrite ]] && answer="y" ||read -p "already installed, force re-install [y/n] : " answer
    if ! [[ "$answer" == "y" ]]; then
        echo "aborting.."
        exit 2
    fi

    [[ -f "$GURU_BIN/uninstall.sh" ]] && bash "$GURU_BIN/uninstall.sh" || echo "un-installer not found"
fi

[[ -f "$HOME/.bashrc.giobackup" ]] || cp -f "$target_rc" "$HOME/.bashrc.giobackup"                    # Make a backup of original .bashrc but only if installed first time
grep -q ".gururc" "$target_rc" || cat ./src/tobashrc.sh >>"$target_rc"                              # Check is .gururc called from .bashrc, add call if not

[[ -f "$disabler_flag_file" ]] && rm -f "$disabler_flag_file"

cp -f ./src/gururc.sh "$HOME/.gururc"                                                               # create folder structure
source "$HOME/.gururc"                                                                              # rise default environmental variables

[[ -d "$GURU_BIN" ]] || mkdir -p "$GURU_BIN"                                                          # make bin folder for script files
[[ -d "$GURU_CFG" ]] || mkdir -p "$GURU_CFG"                                                          # make cfg folder for configuration files
[[ -d "$GURU_APP" ]] || mkdir -p "$GURU_APP"
[[ -d "$GURU_CFG/$GURU_USER" ]] || mkdir -p "$GURU_CFG/$GURU_USER"                                    # personal configurations
cp -f ./cfg/* "$GURU_CFG"                                                                # copy configuration files to configuration folder
cp -f -r ./src/* -f "$GURU_BIN"                                                                     # copy script files to bin folder
mv  "$GURU_BIN/guru.sh" "$GURU_BIN/guru"                                                            # rename guru.sh in bin folder to guru

if ! dpkg -l |grep xserver-xorg >/dev/null; then
        counter.main add "guru-headless-installed" >/dev/null                                             # add installation counter

        echo "headless client successfully installed"
        exit 0
    fi

platform=$(check_distro)                                                                            # check that distribution is compatible
case "$platform" in                                                                                 # different dependent settings

    linuxmint)
        cinnamon_version=$(cinnamon --version |grep -o "[^ ]*$"|cut -f1 -d".")                      # check cinnamon main version number
        if [ "$cinnamon_version" -lt "4" ]; then                                                    # compatible with cinnamon version 3+
            echo "not valid version of cinnamon environment, exiting.."
            exit 2
        else                                                                                        # Install cinnamon tools
            dconf help >/dev/null || sudo apt install dconf-cli                                     # check that cinnamon setting tools is installed
            echo "installed" | xclip -i -selection clipboard >/dev/null || sudo apt install xclip   # check is clipboard tools installed
            xterm -v >/dev/null || sudo apt install xterm                                           # check that xterm is installed
        fi
        add_cinnamon_guru_shortcuts                                                                 # add keyboard sort cuts for cinnamon
        ;;

    ubuntu)
        gnome_version=$(gnome-shell --version |grep -o "[^ ]*$"|cut -f1 -d".")                      # check gnome main version number
        if [ "$gnome_version" -lt "3" ]; then                                                       # compatible with gnome version 3+
            echo "not valid version of gnome environment, exiting.."
            exit 2
        else                                                                                        # Install gnome tools
            dconf help >/dev/null || sudo apt install dconf-cli                                     # check that gnome setting tools is installed
            echo "installed" | xclip -i -selection clipboard >/dev/null || sudo apt install xclip   # check is clipboard tools installed
            xterm -v >/dev/null || sudo apt install xterm                                           # check that xterm is installed
        fi

        add_ubuntu_guru_shortcuts                                                                   # add keyboard sort cuts for ubuntu
        ;;

    *)
        echo "non valid platform $platform"                                                         # if returns something else
        exit 4
esac

counter.main add guru-installed >/dev/null                                                          # add installation counter

echo "successfully installed"                                                                       # all fine
exit 0






