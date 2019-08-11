#!/bin/bash
# giocon work time recorder casa@ujo.guru 2019


main () {
	
	case $command in
				start|change)
					start $@
					return $?
					;;
				end|stop)
				 	end $@
				 	return $?
					;;
		        status)
					status
					return $?
					;;
				report)
					report $@
					return $?
					;;
				cancel)
					cancel 
					return $?
					;;
				edit)
					$GURU_EDITOR "$GURU_TRACKDATA"
					return $?
					;;
				log)
					printf "last logged records:\n$(tail $GURU_TRACKDATA | tr ";" "  ")\n"
					return 0
					;;
		        *)
				 	printf "ujo.guru command line toolkit @ $(guru version)\n"
				 	printf 'Usage guru timer [COMMAND] <at 00:00> [TASK] [PROJECT] [CUSTOMER]\n'            
		            echo "Commands:"            
					printf 'start|change     start timer for target with last customer and project \n'
					printf 'start at [TIME]  start timer at given time in format HH:MM \n'
					printf 'end|stop         end current task \n'
					printf 'end at [TIME]    end current task at given time in format HH:MM \n'
					printf 'cancel           cancels the current task \n'
					printf "report           creates report in .csv format and opens it with $GURU_OFFICE_DOC \n" # TODO
					printf 'log              prints out 10 last tasks from log \n' # TODO
					printf "edit             opens work time log with $GURU_EDITOR\n" # TODO
					printf 'If PROJECT or CUSTOMER is not filled last used one will be used as default\n'
		            return 0
	esac
}


start() {	
	
	# if [ -f $GURU_TRACKSTATUS ]; then 
	#  	end at $(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
	# fi 														

	case "$1" in

		at|from)    
			shift											#; echo "input: "$@
			if date -d "$1" '+%H:%M' >/dev/null 2>&1; then															
				start_time=$(date -d "$1" '+%H:%M') 		
				shift										#; echo "time pass: "$@
			else 
				start_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") 	#; echo "now pass: "$@
			fi

			if date -d "$1" '+%Y%m%d' >/dev/null 2>&1; then															
				start_date=$(date -d "$1" '+%Y%m%d') 		
				shift										#; echo "date pass: "$@
			else															
				start_date=$(date -d "today" '+%Y%m%d')  	#; echo "today pass: "$@
   			fi   			
			;;

		*)			
			start_date=$(date -d "today" '+%Y%m%d')			
			start_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") 	#; echo "no input pass:"$@			
			;;
	esac   		
	
   	timer_start=$(date -d "$start_date $start_time" '+%s')
    
    [ -f $GURU_TRACKLAST ] && . $GURU_TRACKLAST	# customer, project, task only
   	[ "$1" ] &&	task="$1" || task="$last_task"		   	
	[ "$2" ] &&	project="$2" || project="$last_project"
	[ "$3" ] &&	customer="$3" || customer="$last_customer"
    
    printf "timer_start=$timer_start\n" >$GURU_TRACKSTATUS     
    printf "customer=$customer\nproject=$project\ntask=$task\n" >>$GURU_TRACKSTATUS
    nice_date=$(date -d $start_date '+%d.%m.%Y')	
    printf "start: $nice_date $start_time $customer $project $task\n"
}

 round()
 {
   echo $((($1 + $2/2) / $2))
 }


end() {

	if [ -f $GURU_TRACKSTATUS ]; then 	
		. $GURU_TRACKSTATUS 
	else
		echo "timer not started"
		return 13
	fi
	
	[ -f $GURU_TRACKDATA ] || printf "start_date;start;end_date;end;hours;customer;project;task\n">$GURU_TRACKDATA	

	#timer_now=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
		
	case "$1" in

		at|from)    
			shift																	#; echo "input: "$@
			if date -d "$1" '+%H:%M' >/dev/null 2>&1; then															
				end_time=$(date -d "$1" '+%H:%M') 		
				shift																#; echo "time pass: "$@
			else 
				end_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") 	#; echo "now pass: "$@
			fi

			if date -d "$1" '+%Y%m%d' >/dev/null 2>&1; then															
				end_date=$(date -d "$1" '+%Y%m%d') 		
				shift																#; echo "date pass: "$@
			else															
				end_date=$(date -d "today" '+%Y%m%d')  								#; echo "today pass: "$@
   			fi   			
			;;

		*)			
			end_date=$(date -d "today" '+%Y%m%d')			
			end_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") 		#; echo "no input pass:"$@			
			;;
	esac  

	#timer_start=$(date -d "today 10:00" '+%s')									; echo "timer start "$timer_start
	
	#end_time=$(date -d "today 12:15" '+%H:%M')	
	#end_date=$(date -d "today" '+%Y%m%d')	
	#hours=$(date -u -d "0 $timer_end sec - $timer_start sec" +"%H:%M")

	timer_end=$(date -d "$end_date $end_time" '+%s')								; echo "timer end "$timer_end

	(( spend_sec = timer_end - timer_start )) 										; echo "spend_sec: "$spend_sec
	(( spend_min = spend_sec / 60 )) 												; echo "spend_min: "$spend_min
	(( spend_hour = spend_min / 60 ))												; echo "spend_hour: "$spend_hour
	(( spend_min_div = spend_min % 60 ))											; echo "spend_min_div: "$spend_min_div
	spend_min_dec=$(python -c "print(int(round($spend_min_div * 1.6666, 0)))") 		; echo "dec_minutes: "$spend_min_dec 	# 
	hours="$spend_hour.$spend_min_dec"													; echo "hours: "$hours

	(( $spend_sec < 300 )) && end_time=$start_time # less than 5 min is free of charge	
	
	end_date=$(date +%Y.%m.%d)		
	nice_date=$(date -d $timer_start '+%d.%m.%Y')	
	printf "end: $nice_date - $end_time $hours:$minutes $customer $project $task\n"
	printf "$end_date;$start_time;$end_date;$end_time;$hours;$customer;$project;$task\n">>$GURU_TRACKDATA		 		
	printf "last_customer=$customer\nlast_project=$project\nlast_task=$task\n" >$GURU_TRACKLAST	
	rm $GURU_TRACKSTATUS	
}


status() {

	if [ -f $GURU_TRACKSTATUS ]; then
	 	. $GURU_TRACKSTATUS 
	 	timer_now=$(date +%s)			 	
	 	timer_state=$(($timer_now-$timer_start))
	 	printf '%.2d:%.2d:%.2d'" $start_time > $customer $project $task\n" $(($timer_state/3600)) $(($timer_state%3600/60)) $(($timer_state%60))			 	
	else
	 	printf "no timer tasks\n"	
	fi
}


report() {

	if [ "$2" ]; then 
		team="$2" 
	else
		team="all"
	fi
	report_file="$GURU_WORKTRACK/report-$(date +%Y%m%d)-$team.csv"
	[ -f $GURU_TRACKDATA ] || exit 3	
	cat $GURU_TRACKDATA |grep "$2" >$report_file			 	
	soffice $report_file &
	}


cancel() {

	if [ -f $GURU_TRACKSTATUS ]; then			
		rm $GURU_TRACKSTATUS
		echo "canceled"
	else
		echo "not active timer"
	fi
}


command=$1
shift
main $@


