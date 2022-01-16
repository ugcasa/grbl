#!/bin/bash

    TEMP=`getopt --long -o "cCfh:lsu:v:-:" "$@"`
    eval set -- "$TEMP"

    while true ; do
        case "$1" in
            -c ) GURU_COLOR=true        ; shift     ;;
            -C ) GURU_COLOR=false       ; shift     ;;
            -f ) GURU_FORCE=true        ; shift     ;;
            -h ) GURU_HOSTNAME=$2       ; shift 2   ;;
            -l ) GURU_LOGGING=true      ; shift     ;;
            -s ) GURU_VERBOSE=          ; shift     ;;
            -u ) core.change_user "$2"  ; shift 2   ;;
            -v ) GURU_VERBOSE=$2        ; shift 2   ;;
            - ) tallessa=$2             ; shift 2   ;;
             * ) break                  ;;
        esac
    done;

    _arg="$@"

    echo "${_arg[@]} | ${tallessa[@]}"


# while getopts :sc:-: o; do
#     case $o in
#     :) echo >&2 "option -$OPTARG needs an argument"; continue;;
#     '?') echo >&2 "unknown option -$OPTARG"; continue;;
#     -) o=${OPTARG%%=*}; OPTARG=${OPTARG#"$o"}; OPTARG=${OPTARG#=};;
#     esac
#     echo "OPT $o=$OPTARG"
# done
# shift "$((OPTIND - 1))"
# argut=($*)
# for (( i = 0; i < ${#argut[@]}; i++ )); do
# 	#statements
# 	echo "$i: ${argut[$i]}"
# done



# parsed_ops=$(
#   perl -MGetopt::Long -le '

#     @options = (
#       "foo=s", "bar", "neg!"
#     );

#     Getopt::Long::Configure "bundling";
#     $q="'\''";
#     GetOptions(@options) or exit 1;
#     for (map /(\w+)/, @options) {
#       eval "\$o=\$opt_$_";
#       $o =~ s/$q/$q\\$q$q/g;
#       print "opt_$_=$q$o$q"
#     }' -- "$@"
# ) || exit
# eval "$parsed_ops"
# # and then use $opt_foo, $opt_bar...

# echo "$opt_foo, $opt_bar, $opt_neg"
