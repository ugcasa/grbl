

import os



def print_menu():
	print("Network ")
	print("1. Listen network                   5. Listen another network")
	print("2. Change server                    6. Scan WiFi channels")
	print("3. Change network")
	print("Control unit                        Sensor unit ")
	print("11. Request initial information     21. Request initial information")
	print("12. Reset control unit              22. Reset sensor")
	print("13. Remote connection               23. Set measurement interval ")
	print("14. Shutdown control unit           24. Set factory defaults")
	print("15. Update setup")
	print("Other")
	print("30. Device setup                    31. Update tools")

loop=True

while loop:					## While loop which will keep going until loop = False
	os.system('clear')
	print_menu()			
	choice = raw_input("Command: ")
	if choice.isdigit():
		if choice=="1":     
			#print("Menu 1 has been selected")
			os.system('gnome-terminal -x "bash" -c "ls" ')
		elif choice=="2":
			print("Menu 2 has been selected")
			## You can add your code or functions here
		elif choice=="3":
			print("Menu 3 has been selected")
			## You can add your code or functions here
		elif choice=="4":
			print("Menu 4 has been selected")
			## You can add your code or functions here
		elif choice=="5":
			print("Menu 5 has been selected")
			## You can add your code or functions here
			loop=False # This will make the while loop to end as not value of loop is set to False
		else:
			# Any integer inputs other than values 1-5 we print an error message
			raw_input("Wrong option selection. Enter any key to try again..")
	else:	
		print("is not number")

