import argparse
import sqlite3

def output_cookies(ff_cookies, hostname):
    con = sqlite3.connect(ff_cookies)
    cur = con.cursor()
    cur.execute("SELECT host, path, isSecure, expiry, name, value FROM moz_cookies")
    print('{}_COOKIES = {{'.format(hostname.upper().replace('.', '_')))
    for item in cur.fetchall():
        if hostname in item[0]:
            print("  '{}': '{}',".format(item[4], item[5]))
    print('}')
    con.close()

parser = argparse.ArgumentParser()
parser.add_argument('domain', action='store', type=str, help="domain name to filter")
parser.add_argument('database', action='store', type=str, help="database file")
args = parser.parse_args()

output_cookies(args.database, args.domain)
