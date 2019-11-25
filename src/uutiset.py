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

class bc:
    HEADER = '\033[104m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    ITAL = '\033[3m'
    DARK = '\033[4m'
    ENDC = '\033[0m'


def bye_bye():
	print("exit")
	terminal_resize(24, 80)	
	os.system('clear')
	quit()

def terminal_clear():
	print("\n" * term_lines)

def terminal_resize (term_lines, lenght):
	"resize terminal windows on x11. requires xterm install. input term_lines and length. checks first that x11 in use"
	#session_type = os.environ["XDG_SESSION_TYPE"] 
	#if session_type == "x11":
	os.system('resize -s '+str(term_lines)+' '+str(lenght)) 

def terminal_get_size ():
	global term_lines, term_columns, list_lenght_max
	term_lines = int(str(subprocess.check_output('resize -c', shell=True)).split("LINES ",1)[1].split("'")[1].split("'")[0])
	term_columns = int(str(subprocess.check_output('resize -c', shell=True)).split("COLUMNS ",1)[1].split("'")[1].split("'")[0])
	list_lenght_max = term_lines - 3


def print_header (header, logo = "ujo.guru", id = 0, off = 0,):
	if len(header) < term_columns-len(logo):
		
		if term_columns > 60 and id:
			counter = str(id) + "/" + str(off)
		else:
			counter = ""
			
		bar = ' '+' ' * (term_columns-len(header)-1-len(counter)-1-len(logo)-1)
		
	
	print(bc.HEADER+header+bar+' '+counter+' '+logo+bc.ENDC)


def print_publisher_feeds ():

	for i in range(len(feed.entries)):
		global list_lenght, selection
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

		title = title.replace(" ,", ',')
		title = title.replace(' –', ':')
		title = title.replace(' –', ':')

		if term_columns > 90:
			pass
		elif term_columns > 60:
			datestamp = datestamp.split()[1]
		else:
			datestamp = ''
				
		extra_space = 6 + len(datestamp)

		if len(title) < term_columns-extra_space: 
			title += ' ' * (term_columns-extra_space-len(title))

		if i < 9:
			print(' ', end='')		

		title = title[ 0: term_columns - extra_space ]

		if title[-1:] != ' ':
			lastword = title.split()[-1]
			lastword_length = len(lastword) 
			title = title.rsplit(' ', 1)[0]+ '.. '+ (' ' * (lastword_length - 2) )
	
				
		print("["+str(i+1)+"]" +" "+ title[ 0: term_columns - extra_space ] +" "+ datestamp)	
	
	if i < list_lenght_max:
			temp = '\n' * ((list_lenght_max-i)-1)
			print(temp)
	list_lenght=i
	return i


def open_browser (link):
		profile = '--user-data-dir='+os.environ["GURU_CHROME_USER_DATA"]
		browser = os.environ["GURU_BROWSER"]+' '+profile+' '+link+' &'
		os.system(browser)


def open_news (feed_index):

	global list_lenght, selection
	entry = feed.entries[int(feed_index)-1]
	title = entry.title.replace("&nbsp;", "")	
	link = entry.link.replace("&nbsp;", "")			

	try:
		summary = entry.summary.replace("&nbsp;", "")	
	except AttributeError:		
		print("no summary data, opening link")
		open_browser(link)
		return 2
	except:	
		return 3

	summary = entry.summary.replace("&nbsp;", "")	
	
	try:
		json = entry.content

		#if feed.feed.title == "Yle Uutiset | Tuoreimmat uutiset": 			 			# Yle purkka, nimet
		json = str(json).replace('<strong class="yle__article__strong">', '') 
		
		content = ''.join(BeautifulSoup(str(json), "html.parser").stripped_strings).split("'")[13].replace('\\n',"\n ") # bubblecum
		content = content.replace(". ",".\n ")
	except AttributeError:
		content = ""
	except:	
		content = ""


	#os.system('reset') 			# fucks up ssh + phone
	os.system('clear')
	terminal_clear()

	print("\n")
	print_header(feed.feed.title, id = feed_index, off = list_lenght)
	print("\n "+bc.BOLD+ title +bc.ENDC+"\n")
	print("\n "+bc.ITAL+ summary +bc.ENDC+"\n")
	print("\n "+content+"\n")
	print("\n "+bc.DARK+ link +bc.ENDC+"\n") 	
	
	answer = input(bc.OKBLUE+'Hit "o" to open news in browser, news id to jump to news or "Enter" to return to list: '+bc.ENDC)

	if answer == "q" or answer == "exit" or answer == "99": 
		bye_bye()

	if answer == "o" :
		open_browser(entry.link)
	
	if answer == "n" :		
		feed_index = str(int(feed_index) + 1)
		user_input(feed_index)

	if answer == "b":
		feed_index = str(int(feed_index) - 1)
		user_input(feed_index)

	if not answer.isdigit():
		return 0

	if int(answer) < list_lenght:
		open_news(answer)
		return 0
	
	if int(answer) > 99:
		user_input(answer)


def user_input(answer = 0):

	global feed, publisher, list_lenght, selection

	if answer:
		pass
	else:
		answer = input(bc.OKBLUE+'Open news id: '+bc.ENDC)
		print("wait..")

	if answer == "q" or answer == "exit" or answer == "99": 
		bye_bye()

	if answer == "n" and selection < len(feed_list)*100:		
		selection = str(int(selection) + 100)
		user_input(selection)

	if answer == "b" and selection > 100:
		selection = str(int(selection) - 100)
		user_input(selection)
	
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
# later to config file [feed_name] url=, date_format= ..
term_columns = 120
term_lines = 24
list_lenght = 0
list_lenght_max = term_lines - 3

# Open rrs-feed list file    
feed_list_file = open (os.environ["GURU_CFG"]+"/rrs-feed.list", "r")
feed_list = feed_list_file.readlines()
feed_list_file.close()
selection = 100
# date format https://pythonhosted.org/feedparser/date-parsing.html
known_format = ['%a, %d %b %Y %H:%M:%S',\
				'%Y-%m-%dT%H:%M:%S'] 			# http://strftime.org/

terminal_resize(term_lines, term_columns)
publisher = 0
feed = feedparser.parse(feed_list[publisher])
os.system('clear')
while 1:
	terminal_get_size()
	print_header(feed.feed.title, id=selection, off=len(feed_list*100))
	print_publisher_feeds()
	user_input()
