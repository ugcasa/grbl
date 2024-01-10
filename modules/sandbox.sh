#!/bin/bash
# guru-cli sandbox
# casa@ujo.guru 2023

gr.kvt () {

    local width=
    case $1 in -w) shift ; width=$1 shift ; esac

    local input=($@)
    for (( i = 0; i < ${#input[@]}; i + 2 )); do
        echo gr.kv "${input[$i]}" "${input[$(($i+1))]}" "$width"
        i=$(( i + 2 ))
    done
}


gr.kv() {
# print key value pairs

    local variable="$1"; shift
    local value="$1" ; shift
    local column=20

    if [[ $1 ]] && [[ $1 == ?(-)+([0-9]) ]]; then
        column=$1
        shift
    fi
    local colors=(light_blue aqua_marine deep_pink)

    # column=$(expr length $variable)
    if [[ $(expr length $variable) -gt $column ]]; then
        [[ $column -gt 8 ]] \
            && variable="$(head -c$((column - 3)) <<<$variable).." \
            || variable="$(head -c$((column - 1)) <<<$variable)"
    fi

    # printout
    gr.msg -c ${colors[0]} -w$column -n "$variable"
    gr.msg -c ${colors[1]} "$value"
}

gr.kvt -w 40 key value 2 3 4 5 6 7 8 9 100 200 ei muista

