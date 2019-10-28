#!/usr/bin/python3
# rrs news feed
# RSS (Rich Site Summary) is a format for delivering regularly changing web content.
# add to install: sudo pip install --upgrade pip; sudo pip install feedparser




# >>> d.feed.description
# u'For documentation <em>only</em>'
# >>> d.feed.published
# u'Sat, 07 Sep 2002 00:00:01 GMT'
# >>> d.feed.published_parsed
# (2002, 9, 7, 0, 0, 1, 5, 250, 0)

import os
import sys
#import nltk
import ast
import json


from os import system
from datetime import datetime

try:
	import feedparser
except ModuleNotFoundError:
	os.system('pip install --upgrade pip')
	os.system('sudo -H pip install feedparser')
	#exit(124)
finally:
	import feedparser

try:
	from bs4 import BeautifulSoup
except ModuleNotFoundError:
	os.system('pip install --upgrade pip')
	os.system('sudo -H pip install beautifulsoup4')
	#exit(124)
finally:
	from bs4 import BeautifulSoup


try:
	import xml.etree.ElementTree as ET
except ModuleNotFoundError:
	os.system('pip install --upgrade pip')
	os.system('sudo -H pip install elementpath')
	#exit(124)
finally:
	import xml.etree.ElementTree as ET


# later to config file [feed_name] url=, date_format= ..

wide = 120
height = 24
list_length = height - 3

feed_list = ["https://feeds.yle.fi/uutiset/v1/recent.rss?publisherIds=YLE_UUTISET",\
			"http://feeds.bbci.co.uk/news/world/rss.xml",\
			"http://feeds.reuters.com/Reuters/worldNews",\
			"http://www.cbn.com/cbnnews/world/feed/",\
			"http://feeds.bbci.co.uk/news/technology/rss.xml",\
			"https://hackaday.com/blog/feed/"]

feed_list_names = ["yle tuoreimman",\
					"bbc world",\
					"reuters world",\
					"cbn world",\
					"bbc tech",\
					"hackaday tech"]

# date format https://pythonhosted.org/feedparser/date-parsing.html
known_format = ['%a, %d %b %Y %H:%M:%S GMT',\
				'%a, %d %b %Y %H:%M:%S +0300',\
				'%a, %d %b %Y %H:%M:%S +0000',\
				'%Y-%m-%dT%H:%M:%S-05:00',\
				'%Y-%m-%dT%H:%M:%S-04:00',\
				'%a, %d %b %Y %H:%M:%S -0400',\
				'%a, %d %b %Y %H:%M:%S -0500',\
				'%a, %d %b %Y %H:%M:%S-0400'] 			# http://strftime.org/


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


def print_header ():

	feed_title = feed.feed.title	
	header = feed_title 	
	logo = " ujo.guru"
	if len(header) < wide-len(logo):
		header += '-' * (wide-len(header)-len(logo))
	print(header+logo)


def print_feed ():

	for i in range(len(feed.entries)):
		entry = feed.entries[i]

		if i > list_length:
			break
		
		for format_count in range(len(known_format)):
			try:
				datestamp = datetime.strptime(entry.published, known_format[format_count])
				break
			except ValueError:
				pass			#print("unknown date format: "+entry.published)			
			except:
				pass			#print("other fuck-up date format"+entry.published)

		datestamp = datetime.strptime(entry.published, known_format[format_count]).strftime('%d.%m.%y %H:%M')	
		title = entry.title.replace("&nbsp;", "")	
		

		if len(title) < wide-20:
			title += ' ' * (wide-20-len(title))

		if i < 9:
			print(' ', end='')
		
		print("["+str(i+1)+"]" +" "+ title[0:wide-20] +" "+ datestamp)	
	
	if i < list_length:
			temp = '\n' * ((list_length-i)-1)
			print(temp)
	return i



def open_news (feed_index):

	entry = feed.entries[int(feed_index)-1]
	summary = entry.summary.replace("&nbsp;", "")	
	title = entry.title.replace("&nbsp;", "")	
	link = entry.link.replace("&nbsp;", "")			

	#stuff = str(entry.content)[1:-1]
	#xml = ET.fromstring(stuff)
	#print(xml+"\n")
	#content = xml.iter('type')
	 
	try:
		json_string = entry.content
		content = ''.join(BeautifulSoup(str(json_string), "html.parser").stripped_strings).split("'")[13].replace('\\n',"\n") # bubblecum
	except AttributeError:
		content = ""
	except:	
		content = ""
		pass

	os.system('clear')
	print("\n")
	print_header()
	print("\n"+title+"\n\n"+summary)
	print("\n"+content+"\n\n"+link+"\n") 	
	print('"o" or "2" to open in browser, enter to return: ', end = '')
	answer = input()
	
	if answer == "o" or answer == "2":
		profile = '--user-data-dir='+os.environ["GURU_CHROME_USER_DATA"]
		browser = os.environ["GURU_BROWSER"]+' '+profile+' '+entry.link+' &'
		os.system(browser)
	else:
		return 0



def user_input():


	global feed, feed_selection

	print('open news: ', end = '')
	answer = input()
	
	if answer == "q" or answer == "999": 
		ulos()

	if (answer.isdigit()): 				

		selection = int(answer)

		if (selection < 23):			# is feed selection call
			open_news(answer)	
			return 0		
		
		if selection < 100:
			return 1

		selection = selection / 100

		if selection > len(feed_list):
			return 2

		else:
			feed_selection = selection - 1	
			integer = int(feed_selection) 
			feed = feedparser.parse(feed_list[integer])	


## Main

resize_terminal_x11(height, wide)
feed_selection = 0
feed = feedparser.parse(feed_list[feed_selection])

while 1:
	print_header()
	print_feed()
	user_input()
	
	
