#!/bin/bash
# giocon work time recorder casa@ujo.guru 2019

gio_cfg=$HOME/.config/gio
gio_log=$HOME/Dropbox/Notes/casa/WorkTimeTrack
gio_bin=/opt/gio/bin
timer_log=$gio_log/current_work.csv
timer_start_file=/tmp/timer.status
timer_last=/tmp/timer.last

start() {	
	
	[ -f $timer_start_file ] && end
    
    if [ -f $timer_last ]; then
    	. $timer_last			        
    	[ "$2" ] &&	task="$2" || task="$last_task"		       
    	[ "$4" ] &&	customer="$4" || customer="$last_customer"
    	[ "$3" ] &&	project="$3" || project="$last_project"
    fi
    echo "timer_start=$(date +%s)" >$timer_start_file 
    echo "start_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")" >>$timer_start_file
    printf "customer=$customer\nproject=$project\ntask=$task\n" >>$timer_start_file
    printf "start: @ $start_time $customer $project $task\n"
}


end() {
	if [ -f $timer_start_file ]; then 				
		. $timer_start_file 	
		[ -f $timer_log ] || printf "date;start;end;hours;customer;project;task\n">$timer_log
		
		timer_now=$(date +%s)			 	
		timer_state=$(($timer_now-$timer_start))		 		
		end_date=$(date +%Y.%m.%d)
		
		if  (( $timer_state < 300 )) ; then # less than 5 minutes is free
			end_time=$start_time
		else		 			
			end_time=$(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M")
		fi
	
		hours=$(printf '%.2d:%.2d' $(($timer_state/3600)) $(($timer_state%3600/60)))

		printf "$end_date;$start_time;$end_time;$hours;$customer;$project;$task\n">>$timer_log		 		
		printf "end: $start_time - $end_time $hours $customer $project $task\n"
		printf "last_customer=$customer\nlast_project=$project\nlast_task=$task\n" >$timer_last
		#TODO echo 'mosquitto_pub -h "roima" -t "casa/status" -m "done" -u "gio-app" -P "test-salasana"'
		rm $timer_start_file
	else
		echo "timer not started"
	fi
}


status() {
	if [ -f $timer_start_file ]; then
	 	. $timer_start_file 
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
	report_file="$gio_log/report-$(date +%Y%m%d)-$team.csv"
	[ -f $timer_log ] || exit 3	
	cat $timer_log |grep "$2" >$report_file			 	
	soffice $report_file &
	}


cancel() {
	if [ -f $timer_start_file ]; then			
		rm $timer_start_file
		echo "canceled"
	else
		echo "not active timer"
	fi
}

show_log() {
	printf "last logged records:\n$(tail $timer_log | tr ";" "  ")\n"
	[ "$2" = "edit" ] && subl "$timer_log"
}

case "$1" in
			start|change)
				start $@
				;;
			end|stop)
			 	end
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
			log)
				show_log $@
				;;
	        *)
	            echo $"Usage: $0 {start|end|status|change|cancel|report [team]|log [edit]}"
	            echo ""
	            echo "$0 start [task] [project] [team]"
	            exit 1
esac

