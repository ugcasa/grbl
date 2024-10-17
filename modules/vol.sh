#!/bin/bash
# guru-cli adpater
module="audio"
script="vol.sh"

target="$GURU_BIN/$module/$script"
gr.debug "${0##*/} adapting $script to $target"

source "$target"

# if [[ "${BASH_SOURCE[0]}" == "$GURU_CALL" ]] ; then
#     ${target##*/}.main $@
# fi


