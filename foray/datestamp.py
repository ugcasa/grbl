#!/usr/bin/python2.7
# datestamper

import sys
from time import gmtime, strftime

def datestamp(organiz):

    def ordinal(n):
        if 10 <= n % 100 < 20:
            return str(n) + 'th'
        else:
           return  str(n) + {1 : 'st', 2 : 'nd', 3 : 'rd'}.get(n % 10, "th")

    if organiz[:4].upper() == "UJO":
        return strftime("%Y%m%d")

    elif organiz[:4].upper() == "INNO":
        return (strftime("%b")+str(ordinal(int(strftime("%d"))))+strftime("%Y"))

    else:
       return strftime("%Y%m%d")

print(datestamp(sys.argv[1]))

