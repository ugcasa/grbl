
# guru tool-kit launcher to bashrc
export GURU_USER=$USER
if [[ -f ~/.gururc2 ]] ; then
    source ~/.gururc
    source ~/.gururc2
fi
