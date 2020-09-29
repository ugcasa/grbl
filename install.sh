#!/bin/bash
# Installer for guru-client. ujo.guru casa@ujo.guru 2017-2020

GURU_CALL="guru"                                                # default environment variables for installer
GURU_USER="$USER"
GURU_BIN=$HOME/bin
GURU_CFG=$HOME/.config/guru

source core/deco.sh                                          # include decorative functions
source core/os.sh                                            # include os functions

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
       help)    gmsg -c white "guru-client istall help "
                gmsg "Usage: ./install.sh -f|-u <username> "
                gmsg
                gmsg "flags:"
                gmsg " -f --force        force re-install "
                gmsg " -u <username>     set username  "
                gmsg
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

# make a backup of original .bashrc only if installed first time
[[ -f "$HOME/.bashrc.giobackup" ]] || cp -f "$target_rc" "$HOME/.bashrc.giobackup"                  # todo: better method -> add lines to .bashrc file, uninstaller removes added lines
grep -q ".gururc" "$target_rc" || cat core/tobashrc.sh >>"$target_rc"                              # Check is .gururc called from .bashrc, add call if not

[[ -f "$disabler_flag_file" ]] && rm -f "$disabler_flag_file"                                       # todo: remove disabler function

# create folder structure
cp -f core/gururc.sh "$HOME/.gururc"                                                               # todo: user settings should be exported from default user.cfg not like this (stupid)
source "$HOME/.gururc"                                                                              # rise default environmental variables

[[ -d "$GURU_BIN" ]] || mkdir -p "$GURU_BIN"                                                        # make bin folder for script files
[[ -d "$GURU_CFG" ]] || mkdir -p "$GURU_CFG"                                                        # make cfg folder for configuration files
[[ -d "$GURU_APP" ]] || mkdir -p "$GURU_APP"                                                        # todo: remove app folder, not really in use
[[ -d "$GURU_CFG/$GURU_USER" ]] || mkdir -p "$GURU_CFG/$GURU_USER"                                  # personal configurations

cp -f cfg/* "$GURU_CFG"                                                                           # copy configuration files to configuration folder
cp -f -r core/* -f "$GURU_BIN"                                                                     # copy script files to bin folder
cp -f -r modules/* -f "$GURU_BIN"
cp -f -r test -f "$GURU_BIN"
mv  "$GURU_BIN/core.sh" "$GURU_BIN/guru"                                                            # rename guru.sh in bin folder to guru

echo "$(guru version) installed"                                                                       # all fine
exit 0







