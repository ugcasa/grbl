#!/usr/bin/python3
# rrs news feed
# add to install: sudo pip install --upgrade pip; sudo pip install feedparser

import os
import sys
import ast
import json
from os import system
from datetime import datetime
import readline
import subprocess

try:
	import feedparser
except ModuleNotFoundError:
	os.system('pip install --upgrade pip')
	os.system('sudo -H pip install feedparser')
finally:
	import feedparser

try:
	from bs4 import BeautifulSoup
except ModuleNotFoundError:
	os.system('pip install --upgrade pip')
	os.system('sudo -H pip install beautifulsoup4')
finally:
	from bs4 import BeautifulSoup

try:
	import xml.etree.ElementTree as ET
except ModuleNotFoundError:
	os.system('pip install --upgrade pip')
	os.system('sudo -H pip install elementpath')
finally:
	import xml.etree.ElementTree as ET


# later to config file [feed_name] url=, date_format= ..
wide = 120
height = 24
list_lenght = 0
list_lenght_max = height - 3

# Open rrs-feed list file    
feed_list_file = open (os.environ["GURU_CFG"]+"/rrs-feed.list", "r")
feed_list = feed_list_file.readlines()
feed_list_file.close()

# date format https://pythonhosted.org/feedparser/date-parsing.html
known_format = ['%a, %d %b %Y %H:%M:%S',\
				'%Y-%m-%dT%H:%M:%S'] 			# http://strftime.org/


def ulos():
	print("exit")
	resize_terminal_x11(24, 80)	
	os.system('clear')
	quit()


def resize_terminal_x11 (height, lenght):
	"resize terminal windows on x11. requires xterm install. input height and length. checks first that x11 in use"
	#session_type = os.environ["XDG_SESSION_TYPE"] 
	#if session_type == "x11":
	os.system('resize -s '+str(height)+' '+str(lenght)) 


def get_terminal_size ():
	global height, wide, list_lenght_max
	height = int(str(subprocess.check_output('resize -c', shell=True)).split("LINES ",1)[1].split("'")[1].split("'")[0])
	wide = int(str(subprocess.check_output('resize -c', shell=True)).split("COLUMNS ",1)[1].split("'")[1].split("'")[0])
	list_lenght_max = height - 3
	#print( "lines: " + str(height)  )
	#print( "columns: " + str(wide)  )
	

def print_header ():

	feed_title = feed.feed.title	
	header = feed_title 	
	logo = " ujo.guru"
	if len(header) < wide-len(logo):
		header += '-' * (wide-len(header)-len(logo))
	print(header+logo)


def print_feed ():

	for i in range(len(feed.entries)):
		global list_lenght
		entry = feed.entries[i]

		if i > list_lenght_max:
			break
		
		for format_count in range(len(known_format)):
			#print(known_format)	
			try:
				datestamp = datetime.strptime(entry.published.rsplit(' ', 1)[0].rsplit('-', 1)[0], known_format[format_count])
				break
			except ValueError: 		# what?
				pass			
			except:
				pass			

		datestamp = datetime.strptime(entry.published.rsplit(' ', 1)[0].rsplit('-', 1)[0], known_format[format_count]).strftime('%d.%m.%y %H:%M')	
		
		title = entry.title.replace("&nbsp;", "")	
		
		if wide > 90:
			pass
		elif wide > 60:
			datestamp = datestamp.split()[1]
		else:
			datestamp = ''
				
		extra_space = 6 + len(datestamp)

		if len(title) < wide-extra_space: 
			title += ' ' * (wide-extra_space-len(title))

		if i < 9:
			print(' ', end='')		

		print("["+str(i+1)+"]" +" "+ title[0:wide-extra_space] +" "+ datestamp)	
	
	if i < list_lenght_max:
			temp = '\n' * ((list_lenght_max-i)-1)
			print(temp)
	list_lenght=i
	return i


def open_news (feed_index):

	entry = feed.entries[int(feed_index)-1]
	title = entry.title.replace("&nbsp;", "")	
	link = entry.link.replace("&nbsp;", "")			

	try:
		summary = entry.summary.replace("&nbsp;", "")	
	except AttributeError:		
		print("no summary data")
		return 2
	except:	
		return 3

	summary = entry.summary.replace("&nbsp;", "")	
	
	try:
		json_string = entry.content
		content = ''.join(BeautifulSoup(str(json_string), "html.parser").stripped_strings).split("'")[13].replace('\\n',"\n") # bubblecum
	except AttributeError:
		content = ""
	except:	
		content = ""

	os.system('clear')
	print("\n")
	print_header()
	print("\n"+title+"\n\n"+summary)
	print("\n"+content+"\n\n"+link+"\n") 	
	answer = input('"o" to open in browser, enter to return: ')
	
	if answer == "o":
		profile = '--user-data-dir='+os.environ["GURU_CHROME_USER_DATA"]
		browser = os.environ["GURU_BROWSER"]+' '+profile+' '+entry.link+' &'
		os.system(browser)
	else:
		return 0


def user_input():

	global feed, feed_selection, list_lenght

	#print('open news: ', end = '')

	answer = input('open news: ')

	if answer == "q" or answer == "exit": 
		ulos()
	
	if (answer.isdigit()): 				

		selection = int(answer)

		if selection > 0 and selection < 100:			# is feed selection call
			if selection <= list_lenght:
				open_news(answer)						
		else:
			sub_selection = selection % 100			
			select_int = int(selection / 100 - 1)  		# is float
			
			if select_int > len(feed_list) or select_int < 0:
				return 2			
			
			try:
				feed = feedparser.parse(feed_list[select_int])	
			except:	
				return 2

			feed = feedparser.parse(feed_list[select_int])	
			
			if sub_selection > 0: 								
				
				if (sub_selection) > list_lenght:
					return 2

				open_news(sub_selection)	

## Main
resize_terminal_x11(height, wide)
feed_selection = 0
feed = feedparser.parse(feed_list[feed_selection])

while 1:
	get_terminal_size()
	print_header()
	print_feed()
	user_input()
