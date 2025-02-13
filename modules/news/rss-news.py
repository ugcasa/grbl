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
    import xml.etree.ElementTree
except ModuleNotFoundError:
    os.system('pip install --upgrade pip')
    os.system('sudo -H pip install elementpath')
finally:
    import xml.etree.ElementTree as ET

# to get next module to run in non gui environment this is needed
os.environ["DISPLAY"] = ":0"

try:
    import pyautogui
except ModuleNotFoundError:
    os.system('sudo -H pip install pyautogui')
finally:
    from pyautogui import keyDown, press, keyUp


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


class menu:
    # draw a menu and contain variables

    list_length                 = 0
    list_length_max             = 0
    selection                   = 0
    provider                    = 100
    known_date_formats          = [ '%a, %d %b %Y %H:%M:%S', '%Y-%m-%dT%H:%M:%S' ]

    def __init__ ( self, columns, lines ):

        try:
            subprocess.check_output('resize -c', shell=True)
        except subprocess.CalledProcessError:
            os.system('sudo apt install xterm -y')
        finally:
            self.prev_term_columns  = int(
                str(subprocess.check_output( 'resize -c', shell=True ) )\
                .split( "COLUMNS ", 1 )[1]\
                .split( "'" )[1]\
                .split( "'" )[0]\
                )

        self.prev_term_lines    = int(
            str( subprocess.check_output( 'resize -c', shell=True ) )\
            .split( "LINES ", 1 )[1]\
            .split( "'" )[1]\
            .split( "'" )[0]\
            )

        if self.prev_term_columns > columns :
            self.term_columns = self.prev_term_columns
        else :
            self.term_columns = columns

        if self.prev_term_lines > lines :
            self.term_lines = self.prev_term_lines
        else :
            self.term_lines = lines

        self.list_length_max = self.term_lines - 3

        self.resize( self.term_columns, self.term_lines )
        # os.system( 'clear' )

        self.feed_list_file = open( os.environ["GURU_CFG"] + "/" + os.environ["GURU_USER"] + "/rss-feed.list", "r" )
        self.feed_list = self.feed_list_file.readlines()
        self.feed_list_file.close()

        self.feed = feedparser.parse( self.feed_list[0] )


    def clear ( self ):
        "clear the screen. os clear do not work in phone "

        print("\n" * self.term_lines)


    def resize ( self, columns, lines ):
        "resize terminal window"

        self.get_size()
        os.system('resize -s '+str(lines)+' '+str(columns))


    def get_size ( self ):
        "get terminal window size"

        self.term_lines = int(
            str( subprocess.check_output( 'resize -c', shell=True ) )\
            .split( "LINES ",1)[1]\
            .split( "'" )[1]\
            .split( "'" )[0]\
            )

        self.term_columns = int(
            str( subprocess.check_output( 'resize -c', shell=True ) )\
            .split( "COLUMNS ",1)[1]\
            .split( "'" )[1]\
            .split( "'" )[0]\
            )
        self.list_length_max = self.term_lines - 3


    def header ( self, content , logo = "ujo.guru", first = 0, second = 0, separator = "/"):
        "print out the header, title is needed, default logo and optional counter "

        # build numbers
        counter = ""
        if self.term_columns > 60 and len( content ) < self.term_columns - len( logo ):

            if  first:
                counter = str( first )

            if  second:
                counter = counter + separator + str( second )

            counter = counter + " |"

        # build header bar center piece
        bar = ' '+' ' * ( self.term_columns - len( content ) - 1 - len( counter) - 1 - len( logo ) - 1 )

        # build and raw header
        print(bc.HEADER + content + bar + ' ' + counter + ' ' + logo + bc.ENDC)


    def feeds ( self ):
        "print out the list of feed fit in terminal size"

        i = 0
        # parse all titles in feed.entries list
        for i in range( len( self.feed.entries ) ):
            entry = self.feed.entries[ i ]


            # check time stamp formats and select suitable and translate it to wanted format
            for format_count in range( len( m.known_date_formats ) ):

                try:
                    datestamp = datetime.strptime( entry.published.rsplit( ' ', 1 )[0].rsplit( '-', 1 )[0], m.known_date_formats[ format_count ] ).strftime( '%d.%m.%y %H:%M' )
                    break

                # what?
                except ValueError:
                    pass

                except:
                    pass

            # Remove possible html left overs from titles, ugly lines and extra spaces
            title = entry.title.replace( "&nbsp;", "" ).replace( " ,", ',' ).replace( ' –', ':' ).replace( ' –', ':' )

            # select details to be printed out
            if self.term_columns > 90:
                pass

            elif self.term_columns > 60:
                datestamp = datestamp.split()[1]

            else:
                datestamp = ''

            # reserves space for spaces and line number
            base_size = 6 + len( datestamp )

            # space bar
            if len( title ) < self.term_columns - base_size:
                title += ' ' * ( self.term_columns - base_size - len( title ))

            # intended lines 1 - 9
            if i < 9:
                print(' ', end='')

            # cut to right length
            title = title[ 0: self.term_columns - base_size ]

            # check is middle of word
            if title[ -1: ] != ' ':
                # remove last word or piece of it
                lastword = title.split()[ -1 ]
                # check how long it was
                lastword_length = len( lastword )
                # place ".." to end of line
                title = title.rsplit( ' ', 1 )[0] + '.. '+ (' ' * ( lastword_length - 2 ) )

            # record all entries even there is no space in screen
            if i > self.list_length_max:
                continue

            # print out the line
            print( "[" + str( i + 1 ) + "]" + " " + title[ 0: self.term_columns - base_size ] + " " + datestamp)

            # print empty lines to fill the screen
        if i < self.list_length_max:
                print( '\n' * ( ( self.list_length_max - i ) - 1 ) )

            # update list length
        self.list_length = i
        return i


    def input ( self, answer = 0 ):
        "waits user input if not given pre-hand"

        # id not given, ask
        if answer :
            pass

        else :
            answer = input( bc.OKBLUE + 'Open news id: ' + bc.ENDC )
            print( "wait.." )

        # character commands
        if answer == "q" or answer == "exit" or answer == "99":
            self.quit()

        # increment if nor last
        elif answer == "n" and self.provider < len(self.feed_list) * 100:
            self.provider =  self.provider + 100
            self.input ( str( self.provider ) )
            return 0

        # decrement if not first
        elif answer == "b" and self.provider > 100 :
            self.provider =  self.provider - 100
            self.input ( str( self.provider ) )
            return 0

        # Numeral selections
        if not answer.isdigit() :
            return 2

        # is digit can be taken as an select value
        selection = int( answer )

        # is current publisher line number
        if selection > 0 and selection < 100:

            self.selection = selection
            self.feeds()

            if self.selection > self.list_length + 1 :
                return 2

            # open the news
            self.open( int( self.selection) - 1 )


        # other provider
        if selection >= 100 :
            # parse publisher main menu
            provider = int( selection / 100 ) * 100
            # Parse out possible sub sub_selection
            sub_selection = selection % 100

            try:
                # try to parse a feed, if possible valid id
                self.feed = feedparser.parse( self.feed_list[ int( provider / 100 - 1 ) ] )

            # is not valid id
            except:
                print("fuked up id")
                return 2

            self.provider = provider

            # is not negative
            if sub_selection > 0:
                print(sub_selection)
                self.selection = sub_selection
                self.feeds()

                if self.selection > self.list_length + 1 :
                    return 2

                # open the news
                self.open( self.selection - 1)


    def browser ( self, link ):
        "open news link to guru default browser"

        #profile = '--user-data-dir=' + os.environ[ "GURU_CHROME_USER_DATA" ]
        browser = os.environ[ "GURU_PREFERRED_BROWSER" ]
        os.system( browser  + ' ' + link + ' &' ) #+ ' ' + profile)


    def open ( self, news_id ):
        "open news if exist"

        print("opening id " + str( news_id + 1 ) + ".. ")
        entry   = self.feed.entries[ int( news_id ) ]
        title   = entry.title.replace( "&nbsp;", "" )
        link    = entry.link.replace( "&nbsp;", "" )

        #os.environ['foo'] = 'bar'

        subprocess.run('''
        wget $link -O /tmp/$USER/page.html -q
        line=$(grep "og:image" /tmp/$USER/page.html)
        url=$(echo $line | cut -f3 -d "=" | cut -d " " -f1)
        wget ${url//'"'/''} -O /tmp/$USER/news.jpg -q
        ''',
        shell=True, check=True,env={'link': link},
        executable='/bin/bash')
        image_link = "os.environ['url']"
        #image_link = "/tmp/$USER/news.jpg"

        # id 1 above
        if int( news_id ) < 0 or int( news_id ) > self.list_length :
            return 2

        try :
            summary = entry.summary.replace( "&nbsp;", "" )

        except AttributeError:
            print( "no summary data, opening link" )
            self.browser( link )
            return 2

        except :
            print( "error: 3" )
            return 3

        summary = entry.summary.replace( "&nbsp;", "" )

        try:
            json = entry.content
            json = str(json).replace( '<strong class="yle__article__strong">', '' )                                                     # Yle purkka, nimet
            content = ''.join( BeautifulSoup( str( json ), "html.parser" ).stripped_strings ).split( "'" )[13].replace( '\\n',"\n " )   # bubblecum
            content = content.replace( ". ",".\n " )

        except AttributeError:
            content = ""
            print("attributeError")

        except:
            content = ""
            print("Error")

        # parse entry.image.link
        image_link = '/tmp/news.jpg'

        os.system( 'clear' )                                                                            # clear terminal
        #self.clear()
        self.header( self.feed.feed.title, first = self.selection, second = self.list_length)           # header
        print( "\n\n " + bc.BOLD + title     + bc.ENDC + "\n" )                                         # titles
        print( "\n "   + bc.ITAL + summary   + bc.ENDC + "\n" )
        #os.system('tiv -h '+str(menu.term_lines)+' -w '+str(menu.term_columns)+' '+image_link)                 # printout image in text mode
        #if terminal colors on < 256 (like phone terminal)

        # TBD Issue #63 check tiv and clone/compile/install if not present
        # try:
        #     os.system('tiv')
        # except:
        #     os.system('git clone https://github.com/stefanhaustein/TerminalImageViewer.git')
        #     os.system('cd TerminalImageViewer/src/main/cpp')
        #     os.system('make')
        #     os.system('sudo make install')
        # finally:
        #     os.system('tiv '+image_link)

        os.system('tiv '+image_link)                 # printout image in text mode
        print( "\n "   + content + "\n" )
        print( "\n "   + bc.DARK + link      + bc.ENDC + "\n" )
        #print( entry)


        # Holds down the alt key
        pyautogui.keyDown("shift")

        # Presses the tab key once
        pyautogui.press("pageup")
        pyautogui.press("pageup")
        pyautogui.press("pageup")
        pyautogui.press("pageup")


        # Lets go of the alt key
        pyautogui.keyUp("shift")


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
        print( open( os.environ["GURU_LOCAL_NOTES"] ) )


    def quit ( self ) :
        "quit and return terminal size"
        self.resize( self.prev_term_columns, self.prev_term_lines )
        os.system( 'clear' )
        quit()


## MAN

if len(sys.argv) > 1:
    if sys.argv[1] == "help":
        print("usage:    news")
        quit()
    if sys.argv[1] == "status":
        print("no status data")
        quit()



m = menu( \
    int(os.environ[ "GURU_NEWS_TERMINAL_COLUMNS" ]),\
    int(os.environ[ "GURU_NEWS_TERMINAL_LINES" ])\
    )

# sudo apt install imagemagick || yum install ImageMagick
# git clone https://github.com/stefanhaustein/TerminalImageViewer.git
# cd TerminalImageViewer/src/main/cpp
# make
# sudo make install

while 1:
    m.get_size()
    m.header( content = m.feed.feed.title, first = m.provider)
    m.feeds()
    m.input()
