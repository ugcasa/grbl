# Installer for guru-client. ujo.guru casa@ujo.guru 2017-2020
#!/bin/bash
# TODO - re-write whole installer, this is bullshit
# edit: I kind of like straight forward method with installer, cause it's often is straight forward process.

# default environment variables and included functions
GURU_CALL="guru"                                                
GURU_USER="$USER"
GURU_BIN=$HOME/bin
GURU_CFG=$HOME/.config/guru
source core/deco.sh            # include decorative functions
source core/os.sh              # include os functions

# Environmental values rc file
target_rc="$HOME/.bashrc"                                       
# Flag for disabling the rc file
disabler_flag_file="$HOME/.gururc.disabled"                     
TEMP=`getopt --long -o "fu:" "$@"`
eval set -- "$TEMP"

## Process arguments (flags)
while true ; do
    case "$1" in
        -f ) export force_overwrite=true ; shift ;;
        -u ) export GURU_USER=$2         ; shift 2 ;;
         * ) break
    esac
done;
_arg="$@"
[[ "$_arg" != "--" ]] && ARGUMENTS="${_arg#* }"

## Command parser (if any needed)
case "$1" in
       help)    gmsg -c white "guru-client istall help "
                gmsg "Usage: ./install.sh -f|-u <username> "
                gmsg
                gmsg "flags:"
                gmsg " -f --force        force install "
                gmsg " -u <username>     set user name "
                gmsg ;;
esac

## Check installation, reinstall if -f or user input
if grep -q ".gururc" "$target_rc" ; then                                                            
    [[ $force_overwrite ]] && answer="y" ||read -p "already installed, force re-install [y/n] : " answer

    if ! [[ "$answer" == "y" ]]; then
        echo "aborting.."
        exit 2
    fi

    [[ -f "$GURU_BIN/uninstall.sh" ]] && bash "$GURU_BIN/uninstall.sh" || echo "un-installer not found"
fi

## Set up dot rc files

# Check is .gururc called in .bashrc, add call if not
[[ -f "$HOME/.bashrc.giobackup" ]] || cp -f "$target_rc" "$HOME/.bashrc.giobackup"                  
# make a backup of original .bashrc only if installed first time
grep -q ".gururc" "$target_rc" || cat core/tobashrc.sh >>"$target_rc"                              
# todo: remove disabler function, just un install if need to disable the shit
[[ -f "$disabler_flag_file" ]] && rm -f "$disabler_flag_file"                                       

# rise default environmental variables
cp -f core/gururc.sh "$HOME/.gururc"                                                               
source "$HOME/.gururc"                                                                              

## Make folde tructure
# make bin folder for script files
[[ -d "$GURU_BIN" ]] || mkdir -p "$GURU_BIN"                                                        
# personal configurations
[[ -d "$GURU_APP" ]] || mkdir -p "$GURU_APP"                                                        
# make cfg folder for configuration files
[[ -d "$GURU_CFG/$GURU_USER" ]] || mkdir -p "$GURU_CFG/$GURU_USER"                                  

## Copy files
# copy configuration files to configuration folder
cp -f cfg/* "$GURU_CFG"                                                                           
# copy script files to bin folder
cp -f -r core/* -f "$GURU_BIN"                                                                     
cp -f -r modules/* -f "$GURU_BIN"
cp -f -r test -f "$GURU_BIN"
cp -f -r foray -f "$GURU_BIN"                                   # TODO make a flag -d as developlemt to active this
# rename guru.sh in bin folder to guru
mv  "$GURU_BIN/core.sh" "$GURU_BIN/$GURU_CALL"                                                            

## End and clean 
# all fine
echo "$(guru version) installed"                                                                       
exit 0







