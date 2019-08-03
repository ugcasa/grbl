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
	os.system('sudo pip install --upgrade pip')
	os.system('sudo pip install feedparser')
finally:
	import feedparser

def ulos():
	print("exit")
	os.system('resize -s 24 80')
	os.system('clear')
	quit()

wide=160
high=24


feedlist = ["https://feeds.yle.fi/uutiset/v1/recent.rss?publisherIds=YLE_UUTISET",\
			"http://feeds.bbci.co.uk/news/world/rss.xml",\
			"http://feeds.reuters.com/Reuters/worldNews",\
			"http://www.cbn.com/cbnnews/world/feed/",\
			"http://feeds.bbci.co.uk/news/technology/rss.xml"]


#def get_feed (feed_selection, list_length=5):
os.system('resize -s '+str(high)+' '+str(wide)) 

feed_selection = int(sys.argv[1])-1
list_length =  22

feed = feedparser.parse(feedlist[feed_selection])

# http://strftime.org/
known_format = ['%a, %d %b %Y %H:%M:%S GMT',\
				'%a, %d %b %Y %H:%M:%S +0300',\
				'%Y-%m-%dT%H:%M:%S-05:00',\
				'%Y-%m-%dT%H:%M:%S-04:00',\
				'%a, %d %b %Y %H:%M:%S -0400',\
				'%a, %d %b %Y %H:%M:%S -0500',\
				'%a, %d %b %Y %H:%M:%S-0400' ]

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
		

#get_feed(1,5)

print('open news: ', end = '')
a = input()

if a == "q": 
	ulos()


entry = feed.entries[int(a)-1]
browser = os.environ["GURU_BROWSER"]
cmd = browser+' '+entry.link+' &'
os.system(cmd)

ulos()

#https://www.youtube.com/watch?v=L2b9PqSHqe4



