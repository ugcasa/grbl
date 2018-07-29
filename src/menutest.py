

import os
import time
import ConfigParser

cfgFolder = "../cfg"
cfgFile ="setup.cfg"
config = ConfigParser.RawConfigParser()
config.read(cfgFolder+"/"+cfgFile)

menuDelay = int(config.get("menu","delay"))
loop = True			# Menu loop

server = config.get("servers","1")
CUID = config.get("network","cuid")


def print_menu():
	print("Current server: "+svrHost+":"+svrPort+" and network: "+CUID)
	print("Network")
	print("1. Listen network                   4. Scan WiFi channels")
	print("2. Change network")
	print("3. Change server")
	print("Control unit                        Sensor unit")
	print("11. Request initial information     21. Request initial information")
	print("12. Reset control unit              22. Reset sensor")
	print("13. Remote connection               23. Set measurement interval")
	print("14. Shutdown control unit           24. Set factory defaults")
	print("15. Update setup")
	print("Other")
	print("31. Device setup                    32. Update tools")
	print("99. Exit")


while loop:					## While loop which will keep going until loop = False

	svrHost = config.get(server,"host")
	svrPort = config.get(server,"port")
	svrUser = config.get(server,"user")
	svrPass = config.get(server,"password")

	parameters="-u "+svrUser+" -P "+svrPass+" -h "+svrHost+" -p "+svrPort+" -v "
	topic ="-t "+CUID+"/#"

	time.sleep(menuDelay)
	os.system('clear')
	print_menu()			
	choice = raw_input("Command: ")
	if choice.isdigit():
		
	# Network
		if choice=="1":     
			print("Connecting to "+parameters+" topic "+topic)
			command = 'gnome-terminal --command="mosquitto_sub '+parameters+' '+topic+'"'
			os.system(command)
		elif choice=="2":			
			CUID = raw_input("Input control unit ID: ")
		elif choice=="3":
			print("Select server")		
			i = 1
			while config.has_option("servers",str(i)):
				
				print(str(i)+". "+config.get(config.get("servers",str(i)),"name"))
				i += 1

			# print("1. "+config.get(config.get("servers","1"),"name"))
			# print("2. "+config.get(config.get("servers","2"),"name"))
			# print("3. "+config.get(config.get("servers","3"),"name"))
			# print("4. "+config.get(config.get("servers","4"),"name"))

			choice = raw_input("Select: ")
			if config.has_option("servers",choice):
				server = config.get("servers",choice)
			else:
				print("Not valid selection")
			
		elif choice=="4":
			print("Scanning WiFi networks")
			os.system('gnome-terminal --command="nmcli dev wifi"')

	# Control unit
		elif choice=="11":     
			print("11")
		elif choice=="12":
			print("12")
		elif choice=="13":
			print("13")			
		elif choice=="14":
			print("14")
		elif choice=="15":
			print("15")

	# Sensor unit
		elif choice=="21":     
			print("21")
		elif choice=="22":
			print("22")
		elif choice=="23":
			print("23")			
		elif choice=="24":
			print("24")
	
	# Other
		elif choice=="31":     
			print("31")
		elif choice=="32":
			print("32")
		elif choice=="99":
			print("Bye")
			loop=False 
		


		else:
			# Any integer inputs other than values 1-5 we print an error message
			print("Wrong option selection.")

	else:	
		print("Use number to select functionality")





# Connecting to  -u iisy -P freesi123 -h iisycloud.com -p 1883 topic  -t #
# gnome-terminal --command="mosquitto_sub  -u iisy -P freesi123 -h iisycloud.com -p 1883  -t #"
# Failed to parse arguments: Argument to "--command/-e" is not a valid command: 

# Text ended before matching quote was found for #. 
# (The text was 'mosquitto_sub  -u iisy -P freesi123 -h iisycloud.com -p 1883  -t #')
