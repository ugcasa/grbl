declare -xg IP=

ddns.install () {
	
	curl "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
}

ddns.config () {
	
	aws2 configure
}


ddns.ip () {
	IP=$(dig @resolver3.opendns.com myip.opendns.com +short)  # 10 times faster than curl // 0m0,058s
	#IP=$(curl https://api.ipify.org/) // 0m0,532s
	if [[ ! $IP =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ ]]; then
 		gr.msg -c error "got bad external ip '$IP'"
 		return 128
	fi
	echo $IP
}


ddns.update () {

	hosts=( "@" "$1") # Enter your hosts in quotes separated by a space. The first and last characters within the parenthesis need to be spaces.
	domain="ujo.guru" # Your domain name
	password="edc45763b1fa47228ace3daa00ca111e" # The Dynamic DNS password from Namecheap, you'll find it in the control panel for your domain
	webhook="" #discord webhook link

	# Set up some variables
	hosts_updated=""
	hosts_unchanged=""

	# Fetch your WAN IP address and store in a variable
	new_ip=$(dig @resolver3.opendns.com myip.opendns.com +short)

	# Loop through all the hosts and check if they need updating
	for host in ${hosts[*]}
	do
		if [[ $host == "@" ]]; then
			fulldomain=$domain
		elif [[ $host != "@" ]]; then
			fulldomain=$host.$domain
		fi

		# Check if the A record is the same as your current WAN IP, if it is just continue with the next host
		current_ip=$(dig +short $fulldomain @freedns1.registrar-servers.com)
		if [[ $new_ip == $current_ip ]]; then
			hosts_unchanged+="${fulldomain}\n"
			continue
		fi

		# Try to update the DNS record and store the response
		response=$(curl -s "https://dynamicdns.park-your-domain.com/update?host=$host&domain=$domain&password=$password&ip=$new_ip" | sed ':a;N;$!ba;s/\n/\\n/g;s/\"/\\"/g')

		# Check if there's errors in the response
		regex="<ErrCount>([0-1])<\/ErrCount>"
		if [[ $response =~ $regex ]]; then
			if [[ ${BASH_REMATCH[1]} == "0" ]]; then
				hosts_updated+="${fulldomain}\n"

			elif [[ ${BASH_REMATCH[1]} == "1" ]]; then
				# Send a webhook about error
				curl -H "Content-Type: application/json" -d '{"content": "An error was encountered when trying to update '$fulldomain'\n```'"$response"'```"}' $webhook
				# Log to console
				echo -e "An error was encountered when trying to update ${fulldomain}, the response was:\n${response}"
			fi
		fi
	done

	# If any hosts have been updated, send a webhook
	if [[ ! -z "$hosts_updated" ]]; then
		message="The following hosts just had their DNS updated with IP ${new_ip}:\n${hosts_updated}"
		# If any of the hosts were unchanged, mention them in the message.
		if [[ ! -z "$hosts_unchanged" ]]; then
			message+="\nThe following hosts were left unchanged:\n${hosts_unchanged}"
		fi

		# Send webhook
		curl -H "Content-Type: application/json" -d '{"content": "'"$message"'"}' $webhook
		# Log to console
		echo -e "${message}"
	fi

	# If no hosts have been updated, just echo to the console.
	if [[ -z "$hosts_updated" ]]; then
		echo "No hosts have been updated"
	fi

}