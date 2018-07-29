## Freesi air quality system installer tool kit
## Juha Palm / ujo.guru (c) 2018

import os
import time
import ConfigParser
import string
version = 0.6.7

cfgFolder = "../cfg"
cfgFile ="setup.cfg"
config = ConfigParser.RawConfigParser()
config.read(cfgFolder+"/"+cfgFile)

menuDelay = int(config.get("menu","delay"))
loop = True			# Menu loop
safetyOff = 0
server = config.get("servers","1")
CUID = config.get("network","cuid")

def print_menu():
	#print("Current server: "+svrHost+":"+svrPort+" and network: "+CUID)
	print("Current server: "+svrName+" and network: "+CUID)	
	print("network                                                               "+version)
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
	print("99. Exit                            98. Safety mode off")
	if safetyOff: print('Safety mode is set off "yes" is set default answer (except SHD)')

def isvalID(answer):
	if answer != "":
		if all([c in string.ascii_letters+"12345657890" for c in answer]):
			return 1
		else:
			return 0
	else:
		return 0

while loop:					## While loop which will keep going until loop = False

	svrName = config.get(server,"name")
	svrHost = config.get(server,"host")
	svrPort = config.get(server,"port")
	svrUser = config.get(server,"user")
	svrPass = config.get(server,"password")

	parameters="-u "+svrUser+" -P "+svrPass+" -h "+svrHost+" -p "+svrPort
	topic ="-t "+CUID+"/#"

	time.sleep(menuDelay)
	os.system('clear')
	print_menu()			
	choice = raw_input("Command: ")
	if choice.isdigit():
		
	# Network
		if choice=="1":     
			print("Connecting to "+parameters+" topic "+topic)
			command = 'gnome-terminal --command="mosquitto_sub '+parameters+'  '+topic+' -v "'
			os.system(command)
		
		elif choice=="2":			
			answer = raw_input("Input control unit ID: ")
			if isvalID(answer):
				CUID = answer
		
		elif choice=="3":
			print("Select server")		
			i = 1
			while config.has_option("servers",str(i)):			
				print(str(i)+". "+config.get(config.get("servers",str(i)),"name"))
				i += 1
			choice = raw_input("Select: ")
			if config.has_option("servers",choice):
				server = config.get("servers",choice)
			else:
				print("Invalid selection")
			
		elif choice=="4":
			print("Scanning WiFi networks")
			os.system('gnome-terminal --command="nmcli dev wifi"')

	# Control unit
		elif choice=="11":     
			print("11")

		elif choice=="12":
			choice = raw_input("Reset control unit, are you sure? [yes/no]: ")
			if choice == "yes" or safetyOff:
				topic ="-t "+CUID+"/CMD -m RST"
				print("Sending command: "+topic)
				
				command = 'mosquitto_pub '+parameters+' '+topic
				os.system(command)

			else:
				print("Canceling..")

		elif choice=="13":
			print("13")

		elif choice=="14":
			choice = raw_input("SHUTDOWN control unit CAN NOT waken up remotely, are you sure? [yes/no]: ")	
			if choice == "yes" or safetyOff:
				choice = raw_input("Really? [yes/no]: ")
				if choice == "yes":
					topic ="-t "+CUID+"/CMD -m SHD"
					print("Sending command: "+topic)
					
					command = 'mosquitto_pub '+parameters+' '+topic
					os.system(command)
	
				else:
					print("Canceling..")
			else:
				print("Canceling..")

		elif choice=="15":
			print("15")

	# Sensor unit
		elif choice=="21":     
			print("21 is not functional yet")
		elif choice=="22":
			print("22 is not functional yet")
		elif choice=="23":
			print("23 is not functional yet")			
		elif choice=="24":
			print("24 is not functional yet")
	
	# Other
		elif choice=="31":     
			print("31 is not functional yet")
		elif choice=="32":			
			os.system("bash update")
			break
		elif choice=="99":
			print("Bye")
			loop=False 
		elif choice=="98":
			safetyOff = 1

		else:
			# Any integer inputs other than values 1-5 we print an error message
			print("Wrong option selection.")
	else:	
		print("Use number to select functionality")
