

import os
import time
import ConfigParser

cfgFolder = "../cfg"
cfgFile ="setup.cfg"
config = ConfigParser.RawConfigParser()
config.read(cfgFolder+"/"+cfgFile)

menuDelay = int(config.get("menu","delay"))
loop = True			# Menu loop

svrHost = config.get("server","host")
svrPort = config.get("server","port")
svrUser = config.get("server","user")
svrPass = config.get("server","password")
CUID = config.get("network","cuid")


def print_menu():
	print("Current server: "+svrHost+" and network: "+CUID)
	print("Network ")
	print("1. Listen network                   5. Listen another network")
	print("2. Change network                   6. Scan WiFi channels")
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

	server="-u "+svrUser+" -P "+svrPass+" -h "+svrHost+" -p "+svrPort+" -v "
	topic ="-t "+CUID+"/#"

	time.sleep(menuDelay)
	os.system('clear')
	print_menu()			
	choice = raw_input("Command: ")
	if choice.isdigit():
		
	# Network
		if choice=="1":     
			print("Connecting to "+server+" topic "+topic)
			command = 'gnome-terminal --command="mosquitto_sub '+server+' '+topic+'"'
			os.system(command)
		elif choice=="2":			
			CUID = raw_input("Input control unit ID: ")
		elif choice=="3":
			print("3")			
		elif choice=="4":
			print("4")
		elif choice=="5":
			print("5")
		elif choice=="6":
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
