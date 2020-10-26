#!/bin/bash
link=$1
wget $link -O /tmp/page.html
line=$(grep "og:image" /tmp/page.html)
url=$(echo $line | cut -f3 -d "=" | cut -d " " -f1)
wget ${url//'"'/''} -O /tmp/news.jpg