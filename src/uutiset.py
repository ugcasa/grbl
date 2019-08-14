#!/usr/bin/python3
# rrs news feed
# RSS (Rich Site Summary) is a format for delivering regularly changing web content.
# add to install: sudo pip install --upgrade pip; sudo pip install feedparser


import os
import sys
from os import system
from datetime import datetime

try:
	import feedparser
except ModuleNotFoundError:
	print(" installing module")
	os.system('pip install --upgrade pip')
	os.system('sudo -H pip install feedparser')
	exit(124)
finally:
	import feedparser

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

	header = feed_list_names[int(feed_selection)]+" feed "
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
		title=entry.title.replace("&nbsp;", "")	
		summary=entry.summary.replace("&nbsp;", "")	

		if len(title) < wide-20:
			title += ' ' * (wide-20-len(title))

		if i < 9:
			print(' ', end='')
		
		print("["+str(i+1)+"]" +" "+ title[0:wide-20] +" "+ datestamp)	
	
	if i < list_length:
			temp = '\n' * ((list_length-i)-1)
			print(temp)
	return i



def open_news_input (feed_index):

	entry = feed.entries[int(feed_index)-1]
	browser = os.environ["GURU_BROWSER"]
	cmd = browser+' '+entry.link+' &'
	os.system(cmd)


def user_input():

	global feed, feed_selection

	print('open news: ', end = '')
	answer = input()
	
	if (answer.isdigit()): 				

		selection = int(answer)

		if (selection < 23):			# is feed selection call
			open_news_input(answer)	
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

	if answer == "q" or answer == "exit": 
		ulos()

## Main

resize_terminal_x11(height, wide)
feed_selection = 0
feed = feedparser.parse(feed_list[feed_selection])

while 1:
	print_header()
	print_feed()
	user_input()
	
	
