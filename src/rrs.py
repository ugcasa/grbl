#!/usr/bin/python3
# RSS (Rich Site Summary) is a format for delivering regularly changing web content.
# 
# add to install: sudo pip install --upgrade pip; sudo pip install feedparser
#
import feedparser
import os
from datetime import datetime

feedlist = ["https://feeds.yle.fi/uutiset/v1/recent.rss?publisherIds=YLE_UUTISET",\
			"http://feeds.bbci.co.uk/news/world/rss.xml",\
			"http://www.cbn.com/cbnnews/world/feed/",\
			"http://feeds.reuters.com/Reuters/worldNews",\
			"http://feeds.bbci.co.uk/news/technology/rss.xml"]

feed = feedparser.parse(feedlist[0])

# print 5 top topics http://strftime.org/
known_format = ['%a, %d %b %Y %H:%M:%S GMT',\
				'%a, %d %b %Y %H:%M:%S +0300',\
				'%Y-%m-%dT%H:%M:%S-05:00',\
				'%Y-%m-%dT%H:%M:%S-04:00',\
				'%a, %d %b %Y %H:%M:%S -0400',\
				'%a, %d %b %Y %H:%M:%S -0500',\
				'%a, %d %b %Y %H:%M:%S-0400' ]

for i in range(len(feed.entries)):
	entry = feed.entries[i]
	
	for format_count in range(len(known_format)):
		try:
			datestamp = datetime.strptime(entry.published, known_format[format_count])
			break
		except ValueError:
			pass			#print("unknown date format: "+entry.published)			
		except:
			pass			#print("other fuck-up date format"+entry.published)

	datestamp = datetime.strptime(entry.published, known_format[format_count]).strftime('[%d.%m.%y %H:%M]')	
	summary=entry.summary.replace("&nbsp;", "")
	
	print("["+str(i)+"]" +" "+ summary[0:80] +".. "+ datestamp)	#+ ".. "+ entry.link
	#: "+entry.link+"

print('open news nr: ')
a = input()
entry = feed.entries[int(a)]
cmd = 'chromium-browser '+entry.link+' &'
os.system(cmd)
#print("link: "+entry.link)



