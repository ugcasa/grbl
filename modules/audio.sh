#!/bin/bash
# guru-cli adpater
module="audio"
script="main.sh"
target="$GURU_BIN/$module/$script"

gr.debug "${0##*/} adapting $script to $target"

source "$target.sh"