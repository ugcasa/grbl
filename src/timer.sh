#!/bin/bash
# giocon work time recorder casa@ujo.guru 2019


main () {
	
	case $command in
				start|change)
					start $@
					;;
				end|stop)
				 	end $@
					;;
		        status)
					status	
					;;
				report)
					report $@
					;;
				cancel)
					cancel 
					;;
				edit)
					$GURU_EDITOR "$GURU_TRACKDATA"
					;;
				log)
					printf "last logged records:\n$(tail $GURU_TRACKDATA | tr ";" "  ")\n"
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
		            return 1



	esac
}


start() {	
	
	if [ -f $GURU_TRACKSTATUS ]; then 
		end at $(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
	fi

    if [ "$1" == "at" ]; then 
    	shift 						
    	start_time="$1"
    	shift
    else
    	start_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
    fi
	
	timer_start=$(date -d "today $start_time" '+%s')
    
    [ -f $GURU_TRACKLAST ] && . $GURU_TRACKLAST	# customer, project, task only
   	[ "$1" ] &&	task="$1" || task="$last_task"		   	
	[ "$2" ] &&	project="$2" || project="$last_project"
	[ "$3" ] &&	customer="$3" || customer="$last_customer"
    printf "timer_start=$timer_start\nstart_time=$start_time\n" >$GURU_TRACKSTATUS     
    printf "customer=$customer\nproject=$project\ntask=$task\n" >>$GURU_TRACKSTATUS
    printf "start: @ $start_time $customer $project $task\n"
}


end() {

	if [ -f $GURU_TRACKSTATUS ]; then 	
		. $GURU_TRACKSTATUS 
	else
		echo "timer not started"
		return 13
	fi
	
	[ -f $GURU_TRACKDATA ] || printf "date;start;end;hours;customer;project;task\n">$GURU_TRACKDATA	

	timer_now=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
		
	if [ "$1" == "at" ]; then     	
    	shift 						    	
    	end_time="$1"
    	#timer_end=$(date -d "today $end_time" '+%s')
    	shift    	
    else
		end_time=$timer_now
    fi
	
	timer_end=$(date -d "today $end_time" '+%s')	
	spend=$(($timer_end-$timer_start))


	(( $spend < 300 )) && end_time=$start_time # less than 5 min is free of charge	
	
	end_date=$(date +%Y.%m.%d)		
	hours=$(date -u -d "0 $timer_end sec - $timer_start sec" +"%H:%M")
	#minutes=$(date -u -d "0 $timer_end sec - $timer_start sec" +"%-M")
	#dec_minutes=$(python -c "print ($minutes / 60)*100") Ei ymmärrä, jos 15 pitäis tulla 25, vaan tulee 0, % sama
	printf "end: $start_time - $end_time $hours:$minutes $customer $project $task\n"
	printf "$end_date;$start_time;$end_time;$hours;$customer;$project;$task\n">>$GURU_TRACKDATA		 		
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


