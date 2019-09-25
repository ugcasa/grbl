#!/bin/bash
# Some simple functions not complicate enough to write separate scripts
# ujo.guru 2019 

alias docker="resize -s 24 160;docker" 	#TEST

#me=${BASH_SOURCE[0]}

# yes_do () {
# 	[ "$1" ] || return 0
# 	read -p "$1 [y/n]: " answer
# 	[ $answer ] || return 0
# 	[ $answer == "y" ]  && return 1
# }


save () {

	argument=$1
	shift	

	case $argument in

		user-data) 
			save_user_data
			;;
		*)
			echo "hä?"
			;;
	esac
}


save_user_data () {

	[ -f "$GURU_CFG/$GURU_USER" ] || mkdir -p "$GURU_CFG/$GURU_USER"
	echo "saving current setting to permanent user settings"

	if [ -f "$GURU_USER_RC" ]; then 
		read  -r -p  "overwrite current user settings?: " answer
		if [ ! "$answer" == "y" ] ; then 								
			echo "$0: not written" >>"$GURU_ERROR_MSG"
			return 142
		fi		
	fi
	IFS
	echo "# $($GURU_CALL version) personal config file" >"$GURU_USER_RC"
	settings="$(printenv | grep GURU_)"
	for setting in $settings; do 
		variable="${setting%=*}"				; echo "$variable"
		value="${setting#*=}"					; echo "$value"
		echo "export $variable"'="'"$value"'"' 	>>"$GURU_USER_RC"
	done

	#cat $HOME/.gururc | grep "export" | grep -v "#" | grep -v "GURU_USER_RC" >$GURU_USER_RC

}

#for setting in $settings; do echo "$setting";done


remove () {

	argument=$1
	shift

	case $argument in

		user-data) 
			
			if [ "$1" ]; then 
				[ -f "$GURU_CFG/$1/userrc" ] && rm -f "$GURU_CFG/$1/userrc" || return 142
			else			
				[ -f "$GURU_USER_RC" ] && rm -f "$GURU_USER_RC" || return 143
			fi

			;;
		*)
			echo "hä?"
			;;
	esac
}



conda_setup(){

	cat "$HOME/.bashrc" |grep "__conda_setup" || cat "$GURU_BIN/conda_launcher.sh" >>"$HOME/.bashrc"		 #yes cmd < data is better, but do not want to test this again
	
	source "$HOME/.bashrc"
	conda list >>/dev/null || return 14 && 	echo "conda installation found"
	conda config --set auto_activate_base false
	error=$?
	echo "to create and activate environment type: "
	echo "conda create --name my_env python=3"
	echo "conda activate my_env"
	return $error
}


set_value () {

	[ -f "$GURU_USER_RC" ] && target_rc="$GURU_USER_RC" || target_rc="$HOME/.gururc"
	#[ $3 ] && target_rc=$3
	sed -i -e "/$1=/s/=.*/=$2 $3 $4/" "$target_rc"
}


set () {
	# set guru environmental funtions
	argument="$1"
	shift

	case "$argument" in 
			
			current|status)
				[ -f "$GURU_USER_RC" ] && source_rc="$GURU_USER_RC" || source_rc="$HOME/.gururc"
				echo "current settings:"
				cat "$source_rc" |grep "export"| cut -c13-
				;;


			editor)
				[ "$1" ] && new_value=$1 ||	read -p "input preferred editor : " new_value				
				set_value GURU_EDITOR "$new_value"					
				;;

			name)
				[ "$1" ] && new_value=$1 ||	read -p "input new call name for $GURU_CALL : " new_value				
				mv "$GURU_BIN/$GURU_CALL" "$GURU_BIN/$new_value"
				set_value GURU_CALL "$new_value"
				;;

			audio)
				[ "$1" ] &&	new_value=$1 || read -p "new value (true/false) : " new_value
				set_value GURU_AUDIO_ENABLED "$new_value"				
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
				;;
			
			*)				
				[ $1 ] || return 130
				set_value GURU_${argument^^} '"'"$@"'"'
				echo "setting GURU_${argument^^} to $@"
	esac 
}


project () {

	project_name=$1
	# shift

	if [ -z "$project_name" ]; then 
		printf "plase enter project name" >>"$GURU_ERROR_MSG"
		return 131
	fi

	# Turha edes yrittää nysvätä bashilla -> python
	# update 20190823: Vika kyllä taisi olla yes_no funktiossa, tämä saattais toimiakkin 

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
	# 		if yes_do "timer running for different project, change?"; then 
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
		
	# 	if yes_do "start timer?"; then 
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
		printf "no sublime project found" >>"$GURU_ERROR_MSG"
		return 132
	fi	
	
	case $GURU_EDITOR in 
	
			subl|sublime|sublime-text)
				subl --project "$subl_project_file" -a 
				subl --project "$subl_project_file" -a 	# Sublime how to open workpace?, this works anyway
				;;
			*)
			printf 'projects work only with sublime. Set preferred editor by typing: "'$GURU_CALL' set editor subl", or edit "~/.gururc". '	>>"$GURU_ERROR_MSG"
			return 133
	esac


}

pro () {
	# alias
	project $@
	return $?
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
		echo "disabling failed" >>$GURU_ERROR_MSG
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
					echo "no such counter" >>$GURU_ERROR_MSG	
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
					echo "no such counter" >>$GURU_ERROR_MSG
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
	# open slack channel - bubblecum

	if [ "$GURU_BROWSER" == "chromium-browser" ]; then 						# check browser and user data foler, if set
		[ $GURU_CHROME_USER_DATA ] && GURU_BROWSER="$GURU_BROWSER --user-data-dir=$GURU_CHROME_USER_DATA" 
	fi

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

	# echo $GURU_BROWSER
}



relax () {	
	# relaxing music and someting to read, listen or watch
	
	if [ "$GURU_BROWSER" == "chromium-browser" ]; then
		GURU_BROWSER="$GURU_BROWSER --user-data-dir=$GURU_CHROME_USER_DATA"
	fi

	$GURU_CALL play "electric lounge chill low tempo instrumental"
	$GURU_BROWSER \
		https://yle.fi/uutiset \
		https://hackaday.com/ \
		https://areena.yle.fi/radio/ohjelmat/yle-puhe \
		https://areena.yle.fi/1-3822119 \
		>/dev/null &
}


translate () {
	 # terminal based translator

	 if ! [ -f $GURU_BIN/trans ]; then 
	 	cd $GURU_BIN
	 	wget git.io/trans
	 	chmod +x ./trans
	 fi

	if [[ $1 == *"-"* ]]; then
		argument1=$1
		shift		
	else
	  	argument1=""	  	
	fi

	if [[ $1 == *"-"* ]]; then
		argument2=$1
		shift		
	else
	  	argument2=""	  	
	fi

	if [[ $1 == *":"* ]]; then
	  	#echo "iz variable: $variable"
		variable=$1
		shift
		word=$@

	else
	  	#echo "iz word: $word"
	  	word=$@
	  	variable=""
	fi

	$GURU_BIN/trans $argument1 $argument2 $variable "$word"

}

trans (){
	# alias
	translate $@
}


volume () {
    # set volume

    case $1 in 

            mute|unmute)   
                amixer -D pulse set Master toggle  >/dev/null		#; echo "audio mute toggle"
                ;;
            up)   
                str=`amixer set Master 5+` >/dev/null
                vol=`echo $str| awk '{print $22}'`					#; echo "audio $vol"
                ;;
            down) 
                str=`amixer set Master 5-` >/dev/null
                vol=`echo $str| awk '{print $22}'`					#; echo "audio $vol"
                ;;
            *)
                str=`amixer set Master $1` >/dev/null
                vol=`echo $str| awk '{print $22}'`					#; echo "audio $vol"
    esac
}



stop () {

		$GURU_CALL fadedown
		$GURU_CALL play stop
		sleep 1.5
		return $?
}

fadedown () {

    for i in {1..5}
        do
        amixer -M get Master >>/dev/null
        amixer set 'Master' 5%- >>/dev/null
        sleep 0.2
    done
}


fadeup () {

    for i in {1..5}
        do
        amixer -M get Master >>/dev/null
        amixer set 'Master' 5%+ >>/dev/null
        sleep 0.2
    done
    return 0
}


vol () {		# alias 
	volume $@
}

mute () {		# alias 
	volume mute
}

silence () {	# alias
	$GURU_CALL mute
	$GURU_CALL play stop
}
