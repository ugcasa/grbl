# guru tool-kit common functions for installer casa@ujo.guru 2020
# echo "common.sh: included by: $0"

compatible_with(){
    # check that current os is compatible with input [ID] {VERSION_ID}
    
        . /etc/os-release
        #[ "$ID" == "$1" ] && return 0 || return 255
        if [ "$ID" == "$1" ]; then 
            if [ "$VERSION_ID" == "$2" ] || ! [ "$2" ]; then 
                return 0 
            else
                echo "${0} is not compatible with $NAME $VERSION_ID, expecting $2 "
                return 255
            fi
        else
            echo "${0} is not compatible with $PRETTY_NAME, expecting $1 $2"
            return 255
        fi
}


check_distro() {
    # returns least some standasrt type linux distributuin name
    . /etc/os-release
    echo "$ID"
    return 0
}


counter() {
    # Counter case statment  
    
    argument="$1"   ; shift         # arguments     
    id="$1"         ; shift         # counter name
    value="$1"      ; shift         # input value   
    id_file="$GURU_COUNTER/$id"     # counter location
    
    [ -d "$GURU_COUNTER" ] ||mkdir -p "$GURU_COUNTER"

    case "$argument" in

                ls)
                    echo "$(ls $GURU_COUNTER)"
                    exit 0
                    ;;

                get)
                    if ! [ -f "$id_file" ]; then 
                        echo "no such counter" >"$GURU_ERROR_MSG"   
                        return 136
                    fi
                    id=$(($(cat $id_file)))
                    ;;

                add|inc)                    
                    [ -f "$id_file" ] || echo "0" >"$id_file"
                    [ "$value" ] && up="$value" || up=1
                    id=$(($(cat $id_file)+$up))
                    echo "$id" >"$id_file"
                    ;;

                set)
                    [ -z "$value" ] && id=0 || id=$value
                    [ -f "$id_file" ] && echo "$id" >"$id_file" 
                    ;;              

                rm)             
                    id="counter $id_file removed"
                    [ -f "$id_file" ] && rm "$id_file" || id="$id_file not exist"
                    exit 0 
                    ;;  

                help|"")            
                    printf "usage: $GURU_CALL counter [argument] [counter_name] <value>\n"
                    printf "arguments:\n"
                    printf "get                         get counter value \n"
                    printf "ls                          list of counters \n"
                    printf "inc                         increment counter value \n"                 
                    printf "add [counter_name] <value>  add to countre value (def 1)\n"
                    printf "set [counter_name] <value>  set and set counter preset value (def 0)\n"
                    printf "rm                          remove counter \n"  
                    printf "If no argument given returns counter value \n"  
                    return 0
                    ;;

                *)              
                    id_file="$GURU_COUNTER/$argument"
                    if ! [ -f $id_file ]; then 
                        echo "no such counter" >>$GURU_ERROR_MSG
                        return 137
                    fi
                    [ "$id" ] && echo "$id" >$id_file
                    id=$(($(cat $id_file)))
                    
    esac

    echo "$id"      # is not exited before
    return 0
}
