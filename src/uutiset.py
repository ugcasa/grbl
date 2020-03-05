#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ujo.guru rrs news feed 

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


class menu ():

	term_columns 				= 120
	term_lines 					= 24
	list_length 				= 0
	list_length_max 			= 0
	selection 					= 0 								# list selection id
	provider 					= 100 								# news provider ID
	known_date_formats 			= [ '%a, %d %b %Y %H:%M:%S' ,\
					 				'%Y-%m-%dT%H:%M:%S' ] 			# http://strftime.org/

	def __init__ ( self, x, y ):
		
		self.term_columns 		= x
		self.term_lines 		= y
		self.list_length_max	= self.term_lines - 3

		self.resize( self.term_lines, self.term_columns )
		os.system( 'clear' )

		self.feed_list_file 	= open( os.environ["GURU_CFG"] + "/" + os.environ["GURU_USER"] + "/rss-feed.list", "r" )
		self.feed_list 			= self.feed_list_file.readlines()
		self.feed_list_file.close()

		self.feed = feedparser.parse( self.feed_list[0] )


	def clear ( self ):
		"clear the screen. os clear do not work in phone "
		print("\n" * self.term_lines)


	def resize ( self, lines, columns ):
		"resize terminal window"
		os.system('resize -s '+str(lines)+' '+str(columns)) 


	def get_size ( self ):
		"get terminal window size"
		self.term_lines   		= int( str( subprocess.check_output( 'resize -c', shell=True ) ).split( "LINES ",   1 )[1].split( "'" )[1].split( "'" )[ 0 ] ) 			
		self.term_columns 		= int( str( subprocess.check_output( 'resize -c', shell=True ) ).split( "COLUMNS ", 1 )[1].split( "'" )[1].split( "'" )[ 0 ] )
		self.list_length_max 	= self.term_lines - 3		


	def header ( self, content , logo = "ujo.guru", first = 0, second = 0, separator = "/"):
		"print out the header, title is needed, default logo and optional counter "

		# build numbers 
		counter = ""
		if self.term_columns > 60 and len( content ) < self.term_columns - len( logo ):	
			
			if 	first:	
				counter = str( first ) 
			
			if 	second:	
				counter = counter + separator + str( second ) 

			counter = counter + " |"

		# build header bar center piece
		bar = ' '+' ' * ( self.term_columns - len( content ) - 1 - len( counter) - 1 - len( logo ) - 1 )
	
		# build and raw header
		print(bc.HEADER + content + bar + ' ' + counter + ' ' + logo + bc.ENDC)


	def feeds ( self ):
		"print out the list of feed fit in terminal size"
		i = 0 
		for i in range( len( self.feed.entries ) ): 													# parse all titles in feed.entries list
			entry = self.feed.entries[ i ]
			
			
			for format_count in range( len( m.known_date_formats ) ): 									# check time stamp formats and select suitable and translate it to wanted format

				try: 
					datestamp = datetime.strptime( entry.published.rsplit( ' ', 1 )[0].rsplit( '-', 1 )[0], m.known_date_formats[ format_count ] ).strftime( '%d.%m.%y %H:%M' )
					break

				except ValueError: 																		# what?
					pass			

				except:
					pass			
			 																							
			title = entry.title.replace( "&nbsp;", "" ).replace( " ,", ',' ).replace( ' –', ':' ).replace( ' –', ':' )	# Remove possible html left overs from titles, ugly lines and extra spaces	

			if self.term_columns > 90:																	# select details to be printed out
				pass

			elif self.term_columns > 60:
				datestamp = datestamp.split()[1]

			else:
				datestamp = ''
						
			base_size = 6 + len( datestamp ) 					 										# reserves space for spaces and line number

			if len( title ) < self.term_columns - base_size: 											# space bar
				title += ' ' * ( self.term_columns - base_size - len( title ))

			if i < 9: 																					# intended lines 1 - 9
				print(' ', end='')			

			title = title[ 0: self.term_columns - base_size ]											# cut to right length

			if title[ -1: ] != ' ': 																	# check is middle of word
				lastword = title.split()[ -1 ]															# remove last word or piece of it
				lastword_length = len( lastword )  														# check how long it was
				title = title.rsplit( ' ', 1 )[0] + '.. '+ (' ' * ( lastword_length - 2 ) ) 			# place ".." to end of line
		
			if i > self.list_length_max:				 												# record all entries even there is no space in screen
				continue	

			print( "[" + str( i + 1 ) + "]" + " " + title[ 0: self.term_columns - base_size ] + " " + datestamp)	# print out the line 

		if i < self.list_length_max:																	# print empty lines to fill the screen 
				print( '\n' * ( ( self.list_length_max - i ) - 1 ) )

		self.list_length = i 																			# update list length
		return i


	def input ( self, answer = 0 ):
		"waits user input if not given pre-hand"

		if answer : 																					# id not given, ask
			pass

		else :
			answer = input( bc.OKBLUE + 'Open news id: ' + bc.ENDC )
			print( "wait.." )

		if answer == "q" or answer == "exit" or answer == "99":  										# character commands
			self.quit()

		elif answer == "n" and self.provider < len(self.feed_list) * 100:								# increment if nor last
			self.provider =  self.provider + 100 
			self.input ( str( self.provider ) )
			return 0

		elif answer == "b" and self.provider > 100 : 													# decrement if not first
			self.provider =  self.provider - 100 
			self.input ( str( self.provider ) )
			return 0
		
		if not answer.isdigit() : 				 														# Numeral selections 
			return 2

		selection = int( answer ) 																		# is digit can be taken as an select value
		
		if selection > 0 and selection < 100:															# is current publisher line number

			self.selection = selection 
			self.feeds()

			if self.selection > self.list_length + 1 :
				return 2

			self.open( int( self.selection) - 1 )	 							 						# open the news
		

		if selection >= 100 :																			# other provider
			provider = int( selection / 100 ) * 100  									 				# parse publisher main menu 
			sub_selection = selection % 100							 									# Parse out possible sub sub_selection
			
			try:
				self.feed = feedparser.parse( self.feed_list[ int( provider / 100 - 1 ) ] )				# try to parse a feed, if possible valid id
			
			except:	 																					# is not valid id
				print("fukedid")
				return 2

			self.provider = provider 
			
			if sub_selection > 0: 													 					# is not negative
				print(sub_selection)
				self.selection = sub_selection
				self.feeds()

				if self.selection > self.list_length + 1 :
					return 2

				self.open( self.selection  - 1 )	 														# open the news
		

	def browser ( self, link ):
		"open news link to guru default browser"
		profile = '--user-data-dir=' + os.environ[ "GURU_CHROME_USER_DATA" ]
		browser = os.environ[ "GURU_BROWSER" ] + ' ' + profile + ' ' + link + ' &'
		os.system( browser )


	def open ( self, news_id ):
		"open news if "
		print("id: " + str( news_id ) )
		entry 	= self.feed.entries[ int( news_id ) ]
		title	= entry.title.replace( "&nbsp;", "" )	
		link 	= entry.link.replace( "&nbsp;", "" )			

		if int( news_id ) < 0 or int( news_id ) > self.list_length :													# id 1 above
			return 2		

		try :
			summary = entry.summary.replace( "&nbsp;", "" )	

		except AttributeError:		
			print( "no summary data, opening link" )
			self.browser( link )
			return 2

		except :	
			print( "erooer" )
			return 3

		summary = entry.summary.replace( "&nbsp;", "" )	
		
		try:
			json = entry.content			
			json = str(json).replace( '<strong class="yle__article__strong">', '' ) 													# Yle purkka, nimet
			content = ''.join( BeautifulSoup( str( json ), "html.parser" ).stripped_strings ).split( "'" )[13].replace( '\\n',"\n " ) 	# bubblecum
			content = content.replace( ". ",".\n " )
		
		except AttributeError:
			content = ""
			print("attributeError")
		
		except:	
			content = ""
			print("Error")

		os.system( 'clear' ) 																			# clear terminal
		self.clear()
		self.header( self.feed.feed.title, first = self.selection, second = self.list_length) 			# header

		print( "\n\n " + bc.BOLD + title 	 + bc.ENDC + "\n" )											# titles
		print( "\n "   + bc.ITAL + summary   + bc.ENDC + "\n" )
		print( "\n "   + content + "\n" )
		print( "\n "   + bc.DARK + link 	 + bc.ENDC + "\n" ) 	
		
		answer = input(bc.OKBLUE+'Hit "o" to open news in browser, news id to jump to news or "Enter" to return to list: '+bc.ENDC)

		if answer == "q" or answer == "exit" or answer == "99": 
			self.quit()

		elif answer == "o" :
			self.browser( entry.link )

		elif answer == "n" :		
			self.selection = str( int( self.selection ) + 1 )
			self.input( str( self.selection ) )

		elif answer == "b":
			self.selection = str( int( self.selection ) - 1 )
			self.input( str( self.selection ) )

		elif answer == "s":
			self.save_article( m.selection )

		elif not answer.isdigit() :
			return 0

		elif int(answer) < self.list_length + 1:
			self.input( str( answer ) )
			return 0
		
		elif int( answer ) > 99 :
			self.input( str( answer ) )


	def save_article( id ):
		"save article to notes in markdown format"
		print( open( os.environ["GURU_NOTES"] ) )


	def quit ( self ) :
		"quit and return terminal size"
		self.resize( 24, 80 )	
		os.system( 'clear' )
		quit()


## MAN

m = menu( 120, 24 ) 

while 1:
	m.get_size()
	m.header( content = m.feed.feed.title, first = m.provider) 
	m.feeds()
	m.input()
