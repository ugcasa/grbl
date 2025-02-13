# Human resources database editor
# casa@ujo.guru 2023

import os
# import sys
import pandas as pd
import argparse


# Instantiate the parser
parser = argparse.ArgumentParser(description='Contact reader help')

# Required positional argument
parser.add_argument('database_name', type=str,
                    help='database name is required as first argument')

# Optional argument
parser.add_argument('--lines', type=int,
                    help='lines to print')

parser.add_argument('--file', type=str,
                    help='use alternative database file')

args = parser.parse_args()
lines = 500

if args.lines:
    lines = args.lines

if args.file:
    file = args.file
else:
    file = os.environ["GRBL_HR_DATA"]+"/"+args.database_name+".csv"


print("name: "+args.database_name)
print("lines: "+str(lines)+":"+str(args.lines))
print("file: "+file+":"+str(args.file))


pd.set_option('display.max_rows', lines)
database=pd.read_csv(file,
                    header=0,
                    usecols=['Name', 'Given Name', 'Family Name', 'Birthday']).fillna('-')

database.to_json(file+".json", orient='index')


#.sort_values(by=['Birthday'], ascending=True)
