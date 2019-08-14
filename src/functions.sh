# Some simple functions not complicate enough to write separate scripts
# ujo.guru 2019 

alias docker="resize -s 24 160;docker" 	#TEST


yes_no () {
	[ "$1" ] || return 2
	read -p "$1 [y/n]: " answer
	[ $answer ] || return 1
	[ $answer == "y" ]  && return 0 
	return 1
}


conda_setup(){

	cat ~/.bashrc |grep "__conda_setup" || cat "$GURU_BIN/conda_launcher.sh" >>$HOME/.bashrc
	source ~/.bashrc
	conda list >>/dev/null || return 14 && 	echo "conda installation found"
	conda config --set auto_activate_base false
	error=$?
	echo "to create and activate environment type: "
	echo "conda create --name my_env python=3"
	echo "conda activate my_env"
	return $error
}


set_value () {
	sed -i -e "/$1=/s/=.*/=$2/" $HOME/.gururc
}


settings () {

	case "$1" in 
			
			current|status)
				echo "current settings:"
				cat $HOME/.gururc |grep "export"| cut -c13-
				;;

			editor)
				[ "$2" ] && new_value=$2 ||	read -p "input preferred editor : " new_value				
				set_value GURU_EDITOR $new_value					
				;;

			name)
				[ "$2" ] && new_value=$2 ||	read -p "input new call name for $GURU_CALL : " new_value				
				mv $GURU_BIN/$GURU_CALL	$GURU_BIN/$new_value
				set_value GURU_CALL $new_value
				;;

			audio)
				[ "$2" ] &&	new_value=$2 || read -p "new value (true/false) : " new_value
				set_value GURU_AUDIO_ENABLED $new_value				
				;;

			conda)
				conda_setup
				return $?
				;;

			help|-h|--help)
		 		printf "usage: guru set <variable> <value> \narguments: \n"
            	printf "current|status          list of values \n"
            	printf "help|-h|--help          help \n"
            	printf "pre-made setup functions: \n"
				printf 'conda                   setup conda installation \n'
				printf 'audio <true/false>      set audio to "true" or "false" \n'
				printf 'editor <editor>         wizard to set preferred editor \n'				
				;;

			"")
				guru set current
				;;
			
			*)				
				[ $2 ] || return 130
				set_value GURU_${1^^} $2				
				echo "setting GURU_${1^^} to $2"
	esac
}


project () {

	project_name=$1
	# shift

	if [ -z "$project_name" ]; then 
		printf "plase enter project name. "
		return 131
	fi

	# Turha edes yrittää nysvätä bashilla -> python
	# project_array=('guru=(giocon test1 test2 teste3)'\
	# 			   'inno=(genextIR test4 test5)'\
	# 			   'deal=(freesi test6)'\
	# 			   )
	
	# "${projec_array[,b]} ${projec_array[0,1]}" 


	# if [ -f $GURU_TRACKSTATUS ]; then 
	# 	. $GURU_TRACKSTATUS 
	# 	# echo "timer_start "$timer_start
	# 	# echo "start_date "$start_date
	# 	# echo "start_time "$start_time
	# 	# echo "customer "$customer
	# 	# echo "project "$project
	# 	# echo "task "$task			

	# 	if [[ $project != $project_name ]]; then 
	# 		if yes_no "timer running for different project, change?"; then 
	# 			read -p "task description: " task_desc
	# 			$GURU_CALL timer start $task_desc $project_name
	# 		else
	# 			echo no 
	# 		fi
	# 	fi

	# 	echo "timer running for different project, change?"
	# 	echo "project=$project_name" >>$GURU_TRACKSTATUS 
	# else
	# 	[ -f $GURU_TRACKLAST ] && . $GURU_TRACKLAST || return 132
		
	# 	echo "last_task "$last_task
	# 	echo "last_project "$last_project
	# 	echo "last_customer "$last_customer
		
	# 	if yes_no "start timer?"; then 
	# 		$GURU_CALL timer start $project_name
	# 	else
	# 		echo no 
	# 	fi

	# fi
	

# sublime project

	subl_project_folder=$GURU_NOTES/$GURU_USER/project 
	[ -f $subl_project_folder ] || mkdir -p $subl_project_folder

	subl_project_file=$subl_project_folder/$1.sublime-project
	
	if ! [ -f $subl_project_file ]; then 
		printf "no sublime project found "
		return 132
	fi	
	
	case $GURU_EDITOR in 
	
			subl|sublime|sublime-text)
				subl --project "$subl_project_file" -a 
				subl --project "$subl_project_file" -a 	# Sublime how to open workpace?, this works anyway
				;;
			*)
			printf 'projects work only with sublime. Set preferred editor by typing: "'$GURU_CALL' set editor subl", or edit "~/.gururc". '		
			return 133
	esac


}


document () {

	cfg=$HOME/.config/guru.io/noter.cfg
	[[ -z "$2" ]] && template="ujo.guru.004" || template="$2"
	[[ -f "$cfg" ]] && . $cfg || echo "cfg file missing $cfg" | exit 1 
	pandoc "$1" --reference-odt="$notes/$USER/$template-template.odt" -f markdown -o  $(echo "$1" |sed 's/\.md\>//g').odt
	return 0
}


disable () {

	if [ -f "$HOME/.gururc" ]; then 
		mv -f "$HOME/.gururc" "$HOME/.gururc.disabled" 
		echo "giocon.client disabled"
		return 0
	else		
		echo "disabling failed"
		return 134
	fi	
}


upgrade () {

	temp_dir="/tmp/guru"
	source="https://ujoguru@bitbucket.org/ugdev/giocon.client.git"
	
	[ -d $temp_dir ] && rm -rf $temp_dir
	mkdir $temp_dir 
	cd $temp_dir
	git clone $source || exit 666
	guru uninstall 
	cd $temp_dir/giocon.client
	bash install.sh $@
	rm -rf $temp_dir
}



status () {

	printf "\e[3mTimer\e[0m: $(guru timer status)\n" 
	#printf "\e[1mConnect\e[0m: $(guru connect status)\n" 
	return 0
}


test_guru () {

	printf "var: $#: $*\nuser: $GURU_USER \n"
	return 0
}


counter () {

	argument=$1
	shift
	id_file="$GURU_COUNTER/$1"

	case $argument in

			read)
				if ! [ -f $id_file ]; then 
					echo "no such counter"		
					return 136
				fi
				id=$(($(cat $id_file)))
				;;

			inc)
				[ -f $id_file ] || echo 0 >$id_file				
				id=$(($(cat $id_file)+1))
				echo "$id" >$id_file
				;;

			add)
				[ -f $id_file ] || echo 0 >$id_file
				[ -z $2 ] && up=1 || up=$2
				id=$(($(cat $id_file)+$up))
				echo "$id" >$id_file
				;;

			reset)
				[ -z $2 ] && id=0 || id=$2
				[ -f $id_file ] && echo "$id" >$id_file 
				;;				

			remove|rm)				
				id="counter $id_file removed"
				[ -f $id_file ] && rm $id_file || id="$id_file not exist"
				;;	

			*)				
				id_file="$GURU_COUNTER/$argument"
				if ! [ -f $id_file ]; then 
					echo "no such counter"		
					return 137
				fi
				id=$(($(cat $id_file)))

	esac

	echo "$id" 
	return 0
}

inc_counter () {

	id_file="$GURU_COUNTER/$1"
	[ -f $id_file ] || printf 1000 >$id_file
	[ -z $2 ] && up=1 || up=$2
	id=$(($(cat $id_file)+$up))
	echo "$id" >$id_file
	echo "$id" 
	return 0
}

read_counter () {

	id_file="$GURU_COUNTER/$1.id"
	if ! [ -f $id_file ]; then 
		echo "no such counter"		
		return 138
	fi
	id=$(($(cat $id_file)))
	echo "$id" 
	return 0
}


slack () {

	case $1 in 
		
		home|bubble|buble|kupla|koti|maea)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/G0DC74V0F \
			https://app.slack.com/client/T0DBYHPK6/D0DC78PJN \
			https://app.slack.com/client/T0DBYHPK6/C99KU7SG1 \
			>/dev/null &
			;;

		duplicate|random|general)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/C0DC5JD32 \
			https://app.slack.com/client/T0DBYHPK6/G0DC9LPTR \
			https://app.slack.com/client/T0DBYHPK6/C0DC5JDCG \
			>/dev/null &
			;;

		lassila|lab|gurulab|mechanics|electronis|radio)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/CGVFK0WS1 \
			https://app.slack.com/client/T0DBYHPK6/GHNK2ERHR \
			https://app.slack.com/client/T0DBYHPK6/C9A5ZATEY \
			https://app.slack.com/client/T0DBYHPK6/GHNK2ERHR \
			https://app.slack.com/client/T0DBYHPK6/GDVCYR4F7 \
			>/dev/null &
			;;
		
		duuni|work)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/G30H7RZLH \
			https://app.slack.com/client/T0DBYHPK6/G9VTFH74G \
			https://app.slack.com/client/T0DBYHPK6/D9V7167GQ \
			>/dev/null &
			;;

		projektit|hankkeet|project|idea|startup)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/GJ1EK6MHV \
			https://app.slack.com/client/T0DBYHPK6/C8TDJJ095 \
			https://app.slack.com/client/T0DBYHPK6/CHNPV8C2W \
			https://app.slack.com/client/T0DBYHPK6/CB06ESYCA \
			https://app.slack.com/client/T0DBYHPK6/GBJDUV50R \
			https://app.slack.com/client/T0DBYHPK6/GGW451ECX \
			https://app.slack.com/client/T0DBYHPK6/CHP2RK0FK \
			>/dev/null & 
			;;
		
		feed)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/G30H7RZLH \
			https://app.slack.com/client/T0DBYHPK6/CHP2RK0FK \
			https://app.slack.com/client/T0DBYHPK6/G363BM51S \
			https://app.slack.com/client/T0DBYHPK6/G314G4X61 \
			>/dev/null &
			;;

		code|coding)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/C97QYBU3W \
			https://app.slack.com/client/T0DBYHPK6/CAGG8B20G \
			https://app.slack.com/client/T0DBYHPK6/GBJDUV50R \
			>/dev/null &
			;;

		iot)
			$GURU_BROWSER \
			https://app.slack.com/client/T0DBYHPK6/CB06ESYCA \
			https://app.slack.com/client/T0DBYHPK6/CHNPV8C2W \
			https://app.slack.com/client/T0DBYHPK6/GJ1EK6MHV \
			>/dev/null &
			;;

		*)
			$GURU_BROWSER https://app.slack.com/client/T0DBYHPK6/C0DC5JD32 &
			;;
	esac
}



relax () {	
	$GURU_CALL play "electric lounge chill low tempo instrumental"
	$GURU_BROWSER \
		https://yle.fi/uutiset \
		https://hackaday.com/ \
		https://areena.yle.fi/radio/ohjelmat/yle-puhe \
		https://areena.yle.fi/1-3822119 \
		>/dev/null &
}