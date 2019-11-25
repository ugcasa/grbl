#!/bin/bash

counter_main () {

	case "$argument" in

				ls)
					echo "$(ls $GURU_COUNTER)"
					exit 0
					;;

				get)
					if ! [ -f $id_file ]; then 
						echo "no such counter" >>$GURU_ERROR_MSG	
						return 136
					fi
					id=$(($(cat $id_file)))
					;;

				add|inc)					
					[ -f $id_file ] || echo 0 >$id_file
					[ "$value" ] && up="$value" || up=1
					id=$(($(cat $id_file)+$up))
					echo "$id" >$id_file
					;;

				set)
					[ -z $value ] && id=0 || id=$value
					[ -f $id_file ] && echo "$id" >$id_file 
					;;				

				rm)				
					id="counter $id_file removed"
					[ -f $id_file ] && rm $id_file || id="$id_file not exist"
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
					exit 0
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

	echo "$id" 		# is not exited before

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  	
  	argument="$1"	; shift 	# arguments		
	id="$1"			; shift 	# counter name
	value="$1"		; shift 	# imput value	

	id_file=$GURU_COUNTER/$id 	# counter location

    counter_main "$@" 			# alternative values

fi


# inc_counter () {

# 	id_file="$GURU_COUNTER/$1"
# 	[ -f $id_file ] || printf 1000 >$id_file
# 	[ -z $2 ] && up=1 || up=$2
# 	id=$(($(cat $id_file)+$up))
# 	echo "$id" >$id_file
# 	echo "$id" 
# 	return 0
# }


# read_counter () {

# 	id_file="$GURU_COUNTER/$1.id"
# 	if ! [ -f $id_file ]; then 
# 		echo "no such counter"		
# 		return 138
# 	fi
# 	id=$(($(cat $id_file)))
# 	echo "$id" 
# 	return 0
# }
