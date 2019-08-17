#!/bin/bash
# lite version of phoneflush (old POC)
sshpass -V >/dev/null|| sudo apt install sshpass

[ "$1" ] && user="$1" || read -p "input user : " user
[ "$2" ] && password="$2" || read -p "input password : " password

case "$user" in 

	maea)		
		ip="192.168.1.50"
		;;

	casa)
		ip="192.168.1.29"
		;;
	*) 
		printf $"Usage: $0 {casa|maea <password>}\n"
		exit 1
esac


case "$3" in 

		whatsup|wa|-w)
			whatsup="True"		
			;;

		photos|photo|video|videos|-p|-v)
			photos="True"		
			;;

		download|downloads|dl|-d)
			download="True"		
			;;

		pictures|picture|pic|-p)
			pictures="True"		
			;;

		all|"*")
			pictures="True"
			download="True"	
			photos="True"
			whatsup="True"		
			;;

		terminal)
			sshpass -p $password sshfs -oHostKeyAlgorithms=+ssh-dss -p 2223 $user@$ip:/storage/emulated/0 /home/casa/puhelin
			;;

		*)
			all="True"
esac

remove_folder () {
		if [[ "$remove_files" = "y" ]]; then 		
			printf "\e[1mremoving: $1\e[0m\n"
			sshpass -p "$password" ssh "$user@$ip" -p 2223 -oHostKeyAlgorithms=+ssh-dss "rm -rf $1;mkdir -rf $1"
		fi

}
	
copy_photos() {		

		printf "\e[1mcopying photos..\e[0m\n"
		sshpass -p $password scp -v -p -oHostKeyAlgorithms=+ssh-dss -P 2223 $user@$ip:/storage/emulated/0/DCIM/Camera/* /home/casa/bubblebay/Photos/2019
		[ "$?" = "0" ] && remove_folder "/storage/emulated/0/DCIM/Camera/"
}

copy_whatsapp() {

		printf "\e[1mcopying whatsup images..\e[0m\n"
		sshpass -p $password scp -v -p -oHostKeyAlgorithms=+ssh-dss -P 2223 $user@$ip':/storage/emulated/0/WhatsApp/Media/WhatsApp Images/*' /home/casa/bubblebay/Photos/2019/wa
		[ "$?" = "0" ] && remove_folder '/storage/emulated/0/WhatsApp/Media/WhatsApp Images/'

		printf "\e[1mcopying whatsup videos..\e[0m\n"
		sshpass -p $password scp -v -p -oHostKeyAlgorithms=+ssh-dss -P 2223 $user@$ip':/storage/emulated/0/WhatsApp/Media/WhatsApp Video/*' /home/casa/bubblebay/Photos/2019/wa
		[ "$?" = "0" ] && remove_folder '/storage/emulated/0/WhatsApp/Media/WhatsApp Video/'
}

copy_download () {

		printf "\e[1mcopying downloads..\e[0m\n"
		sshpass -p $password scp -v -p -oHostKeyAlgorithms=+ssh-dss -P 2223 $user@$ip:/storage/emulated/0/Download/* $HOME/Donwload 
		[ "$?" = "0" ] && remove_folder "/storage/emulated/0/Download"
}


copy_pictures () {

		printf "\e[1mcopying pictures..\e[0m\n"
		sshpass -p $password scp -v -p -oHostKeyAlgorithms=+ssh-dss -P 2223 $user@$ip:/storage/emulated/0/Pictures/Screenshots/* $HOME/Pictures 
		[ "$?" = "0" ] && remove_folder "/storage/emulated/0/Pictures/Screenshots"
}


read -p "remove photos and videos after copying from phone? [y/N]: " remove_files
[ $photos ] && copy_photos
[ $whatsup ] && copy_whatsapp
[ $download ] && copy_download
[ $pictures ] && copy_pictures



# if [[ "$user" = "casa" ]]; then 
# 	sshpass -p $password scp -v -r -p -oHostKeyAlgorithms=+ssh-dss -P 2223 $user@$ip:/storage/emulated/0/MyTinyScan/Documents/* $HOME/Documents
# fi
#\e[1mTimer\e[0m

# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p2223" maea@192.168.1.50:/storage/emulated/0/WhatsApp/Media/* /home/casa/bubblebay/Photos/2019/wa
# rsync  -avzr -h --progress -e "ssh -oHostKeyAlgorithms=+ssh-dss -p2223" casa@192.168.1.29:/storage/emulated/0/WhatsApp/Media/* /home/casa/bubblebay/Photos/2019/wa
# 	casa@192.168.1.29's password: 
# 	exec request failed on channel 0
# 	rsync: connection unexpectedly closed (0 bytes received so far) [Receiver]
# 	rsync error: unexplained error (code 255) at io.c(235) [Receiver=3.1.2]


# ssh -oHostKeyAlgorithms=+ssh-dss -p2223 casa@192.168.1.29
# 	casa@192.168.1.29's password: 
# 	PTY allocation request failed on channel 0
# 	/system/bin/sh: can't find tty fd: No such device or address
# 	/system/bin/sh: warning: won't have full job control
# 	casa@hwH60:/storage/emulated/0 
