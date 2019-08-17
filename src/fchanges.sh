#!/bin/bash

poll_folder () {
	#check giver folder + subsolders until any file is modified. Output the filename with path
	folder_location=$1
	monitored_action=$2
	[ $2 ] && action_type="-e $monitored_action"
	
	#while file_status=$(inotifywait -q -r $action_type $folder_location); done 	# same as -m
	file_status=$(inotifywait -q -r $action_type $folder_location &)
	
	file_status=${file_status// ${monitored_action^^} /}						 #output is "folder MODIFY filename"
	if [ -f "$file_status" ]; then
		echo "$file_status"
		return 0
	else
		echo "inotify output error: $file_status: not such file"
		return 543
	fi
	echo "type: $monitored_action"
	#done
}

while : ; do
	modified_file=$(poll_folder $GURU_NOTES/$GURU_USER  &)

	echo "file modified: $modified_file"
done


#modified_file=$(poll_folder open $GURU_NOTES/$GURU_USER &)
error_code=$?





# tm_stamp=$(date +%Y%m%d -d "tomorrow")
# tm_year=$(date +%Y -d "tomorrow")
# tm_month=$(date +%m -d "tomorrow")
# tm_folder=$GURU_NOTES/$GURU_USER/$tm_year/$tm_month
# tm_file="$GURU_USER"_note_"$tm_stamp.md"
# found_todos=$(cat $modified_file |grep ">>>" |grep -v '"')
# found_todos=${found_todos//>>>/" -"}	

# echo $tm_folder/$tm_file
# #guru make note tm_stamp
# printf '\n## to do\n\n'"$found_todos"'\n\n' >>$tm_folder/$tm_file
# # [ -f $tm_folder ] || mkdir -p $tm_folder
# exit $error_code
# #[[ ! $error_code -eq "0" ]] && echo "error: $error_code"