#!/bin/bash
# simple file based counter for grbl

counter.main () {

    argument="$1"   ; shift         # arguments
    id="$1"         ; shift         # counter name
    value="$1"      ; shift         # input value
    id_file="$GRBL_LOCAL_COUNTER/$id"   # counter location

    [[ -d "$GRBL_LOCAL_COUNTER" ]] || return 70         # wont fuck up mount mkdir -p "$GRBL_LOCAL_COUNTER"

    case "$argument" in

                status)
                    gr.msg -n -t -V1 "${FUNCNAME[0]}: " ; gr.msg -V1 -c green "ok"
                    for _counter in $(ls $GRBL_LOCAL_COUNTER/*) ; do
                            gr.msg -v1 -c light_blue "${_counter//"$GRBL_LOCAL_COUNTER/"/""} : $(cat $_counter)"
                        done
                        ;;

                ls)
                    echo "$(ls $GRBL_LOCAL_COUNTER)"
                    return 0
                    ;;

                get)
                    if ! [[ -f "$id_file" ]] ; then
                        echo "no such counter"
                        return 72
                    fi
                    id=$(($(cat $id_file)))
                    echo "$id"
                    return 0
                    ;;

                add|inc)
                    [[ -f "$id_file" ]] || echo "0" >"$id_file"
                    [[ "$value" ]] && up="$value" || up=1
                    id=$(($(cat $id_file)+$up))
                    echo "$id" >"$id_file"
                    gr.msg -v 1 "$id"
                    return 0
                    ;;

                set)
                    [[ -z "$value" ]] && id=0 || id=$value
                    [[ -f "$id_file" ]] && echo "$id" >"$id_file"
                    return 0
                    ;;

                rm)
                    id="counter $id_file removed"
                    [[ -f "$id_file" ]] && rm "$id_file" || id="$id_file not exist"
                    return 0
                    ;;

                help|"")
                    gr.msg -v1 -c white "grbl counter help "
                    gr.msg -v2
                    gr.msg -v0 "usage:    $GRBL_CALL counter [argument] [counter_name] <value>"
                    gr.msg -v2
                    gr.msg -v1 -c white "arguments:"
                    gr.msg -v1 " get                         get counter value "
                    gr.msg -v1 " ls                          list of counters "
                    gr.msg -v1 " inc                         increment counter value "
                    gr.msg -v1 " add [counter_name] <value>  add to countre value (def 1)"
                    gr.msg -v1 " set [counter_name] <value>  set and set counter preset value (def 0)"
                    gr.msg -v1 " rm                          remove counter "
                    gr.msg -v2
                    gr.msg -v1 "If no argument given returns counter value "
                    gr.msg -v2
                    return 0
                    ;;

                *)
                    id_file="$GRBL_LOCAL_COUNTER/$argument"
                    if ! [[ -f $id_file ]] ; then
                        echo "no such counter" >>$GRBL_ERROR_MSG
                        return 73
                    fi
                    [[ "$id" ]] && echo "$id" >$id_file
                    id=$(($(cat $id_file)))
                    echo $id

        esac
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    #source common.sh
    counter.main "$@"
fi

