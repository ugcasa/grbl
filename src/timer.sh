#!/bin/bash
# giocon work time recorder casa@ujo.guru 2019

output_folder=$HOME/Dropbox/Notes/casa/WorkTimeTrack
timer_log=$output_folder/current_work.csv
timer_status_file=$output_folder/timer.status
timer_last_file=$output_folder/timer.last

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
					subl "$timer_log"
					;;
				log)
					printf "last logged records:\n$(tail $timer_log | tr ";" "  ")\n"
					;;
		        *)
		            echo $"Usage: $0 {start|end|change|cancel|status|log|edit|report}"
		            echo "Examples"
		            echo "$0 start [task] [project] [team], or start at 10:00 [task] [project] [team]"
		            echo "$0 end, or end at 16:00" 
		            exit 1
	esac
}


start() {	
	
	[ -f $timer_status_file ] && end    

    if [ "$1" == "at" ]; then 
    	shift 						
    	start_time="$1"
    	shift
    else
    	start_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
    fi
    	
	timer_start=$(date -d "today $start_time" '+%s')
    [ -f $timer_last_file ] && . $timer_last_file			            
   	[ "$1" ] &&	task="$1" || task="$last_task"		   	
	[ "$2" ] &&	project="$2" || project="$last_project"
	[ "$3" ] &&	customer="$3" || customer="$last_customer"
    printf "timer_start=$timer_start\nstart_time=$start_time\n" >$timer_status_file     
    printf "customer=$customer\nproject=$project\ntask=$task\n" >>$timer_status_file
    printf "start: @ $start_time $customer $project $task\n"
}


end() {

	if [ -f $timer_status_file ]; then 	
		. $timer_status_file 
	else
		echo "timer not started"
		return 13
	fi
	
	[ -f $timer_log ] || printf "date;start;end;hours;customer;project;task\n">$timer_log	
	timer_now=$(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M")
		
	if [ "$1" == "at" ]; then     	
    	shift 						    	
    	end_time="$1"
    	timer_end=$(date -d "today $1" '+%s')
    	shift    	
    else
		end_time=$timer_now
		timer_end=$(date -d "today $timer_now" '+%s')
    fi
	
	spend=$(($timer_end-$timer_start))


	(( $spend < 300 )) && end_time=$start_time # less than 5 min is free of charge	
	
	end_date=$(date +%Y.%m.%d)		
	hours=$(date -u -d "0 $timer_end sec - $timer_start sec" +"%H:%M")
	#minutes=$(date -u -d "0 $timer_end sec - $timer_start sec" +"%-M")
	#dec_minutes=$(python -c "print ($minutes / 60)*100") Ei ymmärrä, jos 15 pitäis tulla 25, vaan tulee 0, % sama
	printf "end: $start_time - $end_time $hours:$minutes $customer $project $task\n"
	printf "$end_date;$start_time;$end_time;$hours;$customer;$project;$task\n">>$timer_log		 		
	printf "last_customer=$customer\nlast_project=$project\nlast_task=$task\n" >$timer_last_file	
	rm $timer_status_file	
}


status() {

	if [ -f $timer_status_file ]; then
	 	. $timer_status_file 
	 	timer_now=$(date +%s)			 	
	 	timer_state=$(($timer_now-$timer_start))
	 	printf '%.2d:%.2d:%.2d'" $customer $project $task\n" $(($timer_state/3600)) $(($timer_state%3600/60)) $(($timer_state%60))			 	
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
	report_file="$output_folder/report-$(date +%Y%m%d)-$team.csv"
	[ -f $timer_log ] || exit 3	
	cat $timer_log |grep "$2" >$report_file			 	
	soffice $report_file &
	}


cancel() {

	if [ -f $timer_status_file ]; then			
		rm $timer_status_file
		echo "canceled"
	else
		echo "not active timer"
	fi
}


command=$1
shift
main $@


