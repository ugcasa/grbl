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
                    help='account name is required as first argument')

parser.add_argument('--lines', type=int,
                    help='lines to print')

parser.add_argument('--file', type=str,
                    help='csv file name')

args = parser.parse_args()
lines = 500

if args.lines:
    lines = args.lines

if args.file:
    file = args.file
else:
    file = os.environ["GRBL_OP_DATA"]+"/"+args.database_name+".csv"

print("name: "+args.database_name)
print("file: "+file)
print("lines: "+str(lines))

df = pd.read_csv(file,
        sep=';',
        header=0,
        usecols=['Arvopäivä',
                 'Määrä EUROA',
                 'Laji',
                 'Saaja/Maksaja',
                 'Saajan tilinumero',
                 'Viite',
                 'Viesti',
                 'Arkistointitunnus']).replace('ref=','')

# https://datagy.io/pandas-dataframe-to-json/
df.to_json(file+".json", orient='index')




# pd.set_option('display.max_rows', lines)

# database=pd.read_csv(os.environ["GRBL_OP_DATA"]+"/"+args.database_name+".csv",
#         sep=';',
#         header=0,
#         usecols=['Arvopäivä',
#                  'Määrä EUROA',
#                  'Laji',
#                  'Saaja/Maksaja',
#                  'Saajan tilinumero',
#                  'Viite',
#                  'Viesti'])

# print(database.fillna('').replace('ref=',''))