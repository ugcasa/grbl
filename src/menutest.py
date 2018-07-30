## Freesi air quality system installer tool kit
## Juha Palm / ujo.guru (c) 2018
import os
import time
import ConfigParser
import string
import readline
import socket

version = "0.6.9"
cfgFolder = "../cfg"
cfgFile ="setup.cfg"
config = ConfigParser.RawConfigParser()
config.read(cfgFolder+"/"+cfgFile)
networksFile ="networks.cfg"
networks = ConfigParser.RawConfigParser()
networks.read(cfgFolder+"/"+networksFile)
menuDelay = int(config.get("menu","delay"))
loop = True			# Menu loop
safetyOff = 0
server = config.get("servers","1")
CUID = config.get("network","cuid")
networkname = ""

def isvalID(answer):
	if answer != "":
		if all([c in string.ascii_letters+"12345657890+" for c in answer]): return 1
		else: return 0
	else: return 0

def print_menu():
	time.sleep(menuDelay)
	os.system('clear')	
	print("Freesi install toolkit " + 45 * "-" + " v"+version+"\n")	
	print(" Network")
	print("  1. Listen network                   4. Known locations")
	print("  2. Change network")				 
	print("  3. Change server"+"\n")
	print(" Control unit                        Sensor unit")
	print("  11. Request initial information     21. Request initial information")
	print("  12. Reset control unit              22. Reset sensor")
	print("  13. Remote connection               23. Set measurement interval")
	print("  14. Close tunnel                    24. Set factory defaults")
	print("  19. Shutdown control unit ")

	print(" Other")
	print("  w. Scan WiFi networks")
	print("  d. Device setup                    u. Update tools")
	print("  q. Exit                            s. Safety mode toggle"+"\n")
	print(75 * "-")
	if safetyOff: print('Safety mode is set off "yes" is set default answer (except SHD)')
	print("Server: "+svrName+", network: "+CUID+" "+networkname)	

def listenNetwork():
	print("Connecting to "+parameters+" topic "+topic)
	command = 'gnome-terminal --command="mosquitto_sub '+parameters+'  '+topic+' -v "'
	os.system(command)

def changeNetwork():
	global CUID, networkname
	answer = raw_input("Input Control Unit ID: ")
	if isvalID(answer):
		CUID = answer
		networkname = ""

def knownNetwork():
	global CUID, server, networkname
	array = []
	i = 1
	a = 1
	while networks.has_section(str(i)):		
		if networks.get(str(i),"status") == "active":
			print(str(a)+". "+networks.get(str(i),"name"))
			array.append(i)
			a += 1
		i += 1
	answer = raw_input("Selection: ")
	if answer.isdigit():
		if int(answer) < a:		
			CUID = networks.get(str(array[int(answer)-1]),"cuid")
			server = config.get("servers","1")
			networkname = networks.get(str(array[int(answer)-1]),"name")
		else: print("not valid selection")
	else: print("not valid selection")

def changeServer():
	global server
	print("Known server list")		
	i = 1
	while config.has_option("servers",str(i)):			
		print(str(i)+". "+config.get(config.get("servers",str(i)),"name"))
		i += 1
	choice = raw_input("Select: ")
	if config.has_option("servers",choice):
		server = config.get("servers",choice)
	else: print("Invalid selection")

def scanWiFi():
	print("Scanning WiFi networks")
	os.system('gnome-terminal --command="nmcli d wifi && read"')

def resetControlUnit():
	choice = raw_input("Reset control unit, are you sure? [yes/no]: ")
	if choice == "yes" or safetyOff:
		topic ="-t "+CUID+"/CMD -m RST"
		print("Sending command: "+topic)
		command = 'mosquitto_pub '+parameters+' '+topic
		os.system(command)
	else: print("Canceling..")

def shutdownControlUnit():
	choice = raw_input("SHUTDOWN control unit CAN NOT waken up remotely, are you sure? [yes/no]: ")	
	if choice == "yes" or safetyOff:
		choice = raw_input("Really? [yes/no]: ")
		if choice == "yes":
			topic ="-t "+CUID+"/CMD -m SHD"
			print("Sending command: "+topic)
			command = 'mosquitto_pub '+parameters+' '+topic
			os.system(command)
		else: print("Canceling..")
	else: print("Canceling..")


def remoteConnection():
	#currentpid = 
	#os.system("sudo netstat -tulpna | grep 2018 |grep aqc |grep 127.0.0.1 | grep -o 'LISTEN.*/' |grep -o '[[:digit:]]*'")
	if socket.gethostname() != "estella":
		print("Remote only functional in Juha's PC")
		return 1
	
	currentpid = os.popen("sudo netstat -tulpna | grep 2018 |grep aqc |grep 127.0.0.1 | grep -o 'LISTEN.*/' |grep -o '[[:digit:]]*'").read()
	if currentpid == "":
		print("no reverse tunnels detected")
	else:
		print("Active tunnel detected pid: "+currentpid)
		
		topic ="-t "+CUID+"/CMD -m OFF"			# Shutdown the open tunnel if from current CUID
		print("Sending command: "+topic)		
		command = 'mosquitto_pub '+parameters+' '+topic
		os.system(command)

		time.sleep(7)		
		command = "sudo kill -9 "+currentpid 	# Kill the tunnel even it is not from current CUID
		os.system(command)

	time.sleep(2)
	topic ="-t "+CUID+"/CMD -m SSH"			# Open tunnel request to CUID
	print("Sending command: "+topic)		
	command = 'mosquitto_pub '+parameters+' '+topic
	os.system(command)
	time.sleep(7)

	os.system('gnome-terminal --command="ssh pi@localhost -p2018"')

def closeConnection():
	topic ="-t "+CUID+"/CMD -m OFF"			# Shutdown the open tunnel if from current CUID
	print("Sending command: "+topic)		
	command = 'mosquitto_pub '+parameters+' '+topic
	os.system(command)


def updateTools():
	global loop
	os.system("bash update")	
	loop=False 

def exitTools():	
	global loop
	print("Bye bye!")
	loop=False 

def getConfig():
	global parameters, topic, svrName
	svrName = config.get(server,"name")
	svrHost = config.get(server,"host")
	svrPort = config.get(server,"port")
	svrUser = config.get(server,"user")
	svrPass = config.get(server,"password")
	parameters="-u "+svrUser+" -P "+svrPass+" -h "+svrHost+" -p "+svrPort
	topic ="-t "+CUID+"/#"

def toggleSafety():
	global safetyOff
	if safetyOff == 0: safetyOff = 1
	else: safetyOff = 0

while loop:					## While loop which will keep going until loop = False
	getConfig()
	print_menu()	
	choice = raw_input("Command: ")
	# Network
	if choice=="1": listenNetwork()	
	elif choice=="2": changeNetwork()		
	elif choice=="3": changeServer()
	elif choice=="4": knownNetwork()
	# Control unit
	elif choice=="11": print("11 is not functional")
	elif choice=="12": resetControlUnit()
	elif choice=="13": remoteConnection()
	elif choice=="14": closeConnection()
	elif choice=="19": shutdownControlUnit()

	# Sensor unit
	elif choice=="21": print("21 is not functional")
	elif choice=="22": print("22 is not functional")
	elif choice=="23": print("23 is not functional")			
	elif choice=="24": print("24 is not functional")
	# Other
	elif choice=="w": scanWiFi()
	elif choice=="d": print("device setup is not functional")
	elif choice=="u": updateTools()
	elif choice=="q": exitTools()
	elif choice=="s": toggleSafety()
	else: print("Wrong option selection.")
