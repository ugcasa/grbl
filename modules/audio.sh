#!/bin/bash
# guru-cli adpater
module="audio"
sub_module="${GURU_COMMAND[0]}.sh"
target="$GURU_BIN/$module/$sub_module"
gr.debug "${0##*/} adapting $sub_module to $target"
source $target
