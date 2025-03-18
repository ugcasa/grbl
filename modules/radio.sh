#!/bin/bash
# grbl adpater
module="audio"
script="radio.sh"
target="$GRBL_BIN/$module/$script"

gr.debug "${0##*/} adapting $script to $target"

source "$target"