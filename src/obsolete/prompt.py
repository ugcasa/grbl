#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import readline
import string
import sys

readline.write_history_file("/home/casa/.guru.history")

guru_call = str(sys.argv[1])
user = str(sys.argv[2])
white = "\033[1;37;40m"
reset = "\033[0m"

# for i in range(readline.get_current_history_length()):
#     print (readline.get_history_item(i + 1))

#while 1:
print ( white + user + "@" + guru_call + ":> " + reset )
choice = input()
print ( choice ) 
#sys.exit(choice)
