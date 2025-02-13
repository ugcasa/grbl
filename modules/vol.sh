#!/bin/bash
# grbl adpater
module="audio"
script="vol.sh"

target="$GRBL_BIN/$module/$script"
gr.debug "${0##*/} adapting $script to $target"

source "$target"

# if [[ "${BASH_SOURCE[0]}" == "$GRBL_CALL" ]] ; then
#     ${target##*/}.main $@
# fi


