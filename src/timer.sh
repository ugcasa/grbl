#!/bin/bash
# giocon work time recorder casa@ujo.guru 2019

gio_cfg=$HOME/.config/gio
gio_log=$HOME/Dropbox/Notes/casa/WorkTimeTrack
gio_bin=/opt/gio/bin
timer_log=$gio_log/current_work.csv
timer_start_file=/tmp/timer.status

case "$1" in
		start)
	        if [ ! -f $timer_start_file ]; then 
		        echo "timer_start=$(date +%s)" >$timer_start_file 
		        echo "start_time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")" >>$timer_start_file
		        echo "customer=$2" >>$timer_start_file
		        echo "project=$3" >>$timer_start_file
		    else
		    	echo "timer is in use"
		    fi
			;;
		
		end)
		 	if [ -f $timer_start_file ]; then 
		 		
		 		. $timer_start_file 	
		 		#[ -f $timer_log ] || touch $timer_log
		 		[ -f $timer_log ] || printf "date;start;end;hours;customer;project\n">$timer_log
		 		
		 		timer_now=$(date +%s)			 	
		 		timer_state=$(($timer_now-$timer_start))		 		
		 		end_date=$(date +%Y.%m.%d)
		 		
		 		if  (( $timer_state < 300 )) ; then # less than 5 minutes is free
		 			end_time=$start_time
		 		else		 			
		 			end_time=$(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M")
		 		fi
		 	
		 		hours=$(printf '%.2d:%.2d' $(($timer_state/3600)) $(($timer_state%3600/60)))
		 		printf "$end_date;$start_time;$end_time;$hours;$customer;$project\n">>$timer_log		 		
		 		printf "$end_date $start_time - $end_time $hours $customer $project\n"
				rm $timer_start_file
			else
				echo "timer not started"
			fi
		 		#output="$end_date $start_time - $end_time $hours h $customer $project\n"
		 		#printf "$(gio.stamp date -h) $start_time - $(gio.stamp end) " #>>$timer_log
		 		#printf '%.2d:%.2d' $(($timer_state/3600)) $(($timer_state%3600/60)) $(($timer_state%60)) #>>$timer_log
         		#$(($timer_state/3600)) $(($timer_state%3600/60)) $(($timer_state%60)) #>>$timer_log
			;;

        status)
			if [ -f $timer_start_file ]; then
			 	. $timer_start_file 
			 	timer_now=$(date +%s --utc)			 	
			 	timer_state=$(($timer_now-$timer_start))
			 	printf '%.2d:%.2d:%.2d'" $customer $project\n" $(($timer_state/3600)) $(($timer_state%3600/60)) $(($timer_state%60))
			else
			 	echo "no timer tasks"			 	
			 	printf "last logged records:\n$(tail $timer_log | tr ";" "  ")\n"
			fi
			;;

		report)
			report_file="$gio_log/report-$(date +%Y%m%d)$2.csv"
			[ -f $timer_log ] || exit 3	
			cat $timer_log |grep "$2" >$report_file			 	
			soffice $report_file &
			;;
			

		cancel)
			if [ -f $timer_start_file ]; then			
				rm $timer_start_file
				echo "canceled"
			fi
			;;

        *)
            echo $"Usage: $0 {start|end|status|cancel|report}"
            exit 1
esac

