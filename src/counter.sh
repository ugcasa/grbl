#!/bin/bash
# simple file based counter for guru tool-kit

counter.main () {
	# Counter case statment

	argument="$1"	; shift 		# arguments
	id="$1"			; shift 		# counter name
	value="$1"		; shift 		# input value
	id_file="$GURU_COUNTER/$id" 	# counter location

 	[[ -d "$GURU_COUNTER" ]] || return 70 		# wont fuck up mount mkdir -p "$GURU_COUNTER"

	case "$argument" in

				ls)
					echo "$(ls $GURU_COUNTER)"
					return 0
					;;

				get)
					if ! [[ -f "$id_file" ]] ; then
						echo "no such counter" >"$GURU_ERROR_MSG"
						return 72
					fi
					id=$(($(cat $id_file)))
					GURU_VERBOSE=1
					;;

				add|inc)
					[[ -f "$id_file" ]] || echo "0" >"$id_file"
					[[ "$value" ]] && up="$value" || up=1
					id=$(($(cat $id_file)+$up))
					echo "$id" >"$id_file"
					;;

				set)
					[[ -z "$value" ]] && id=0 || id=$value
					[[ -f "$id_file" ]] && echo "$id" >"$id_file"
					;;

				rm)
					id="counter $id_file removed"
					[[ -f "$id_file" ]] && rm "$id_file" || id="$id_file not exist"
					return 0
					;;

				help|"")
					printf "usage: $GURU_CALL counter [argument] [counter_name] <value>\n"
					printf "arguments:\n"
					printf " get                         get counter value \n"
					printf " ls                          list of counters \n"
					printf " inc                         increment counter value \n"
					printf " add [counter_name] <value>  add to countre value (def 1)\n"
					printf " set [counter_name] <value>  set and set counter preset value (def 0)\n"
					printf " rm                          remove counter \n"
					printf "If no argument given returns counter value \n"
					return 0
					;;

				*)
					id_file="$GURU_COUNTER/$argument"
					if ! [[ -f $id_file ]] ; then
						echo "no such counter" >>$GURU_ERROR_MSG
						return 73
					fi
					[[ "$id" ]] && echo "$id" >$id_file
					id=$(($(cat $id_file)))
					GURU_VERBOSE=1
	esac

	msg "$id\n" 		# is not exited before
	return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
  	counter.main "$@" 			# alternative values
fi

