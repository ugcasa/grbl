#!/bin/bash 
# tools to set up dokuwiki

dokuwiki.upgrade-local () {
# based on instructions: https://www.dokuwiki.org/install:upgrade 
	
	tar zcpfv dokuwiki-backup.tar.gz /path/to/dokuwiki

	cd /tmp
	wget https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz

	tar zxvf dokuwiki-stable.tgz
	# The quotes on cp assure that it will run as is, even if an alias is set.
	'cp' -af dokuwiki-xxxx-xx-xx/* /path/to/dokuwiki/

	 # DokuWiki continues to show the update message, even though the number in doku.php was increased by the upgrade. 1)
	 rm data/cache/messages.txt
	 # OR touch /path/to/dokuwiki/ doku.php

}

echo "dokuwiki_functions:$dokuwiki_functions tock"


# 1)  This is because DokuWiki caches already fetched messages for a day and will only refetch if the last modified 
#     timestamp of doku.php is higher than the one of the cache file. To stop the outdated update message from showing 
#     you can simply wait a day, touch1) the doku.php or delete the data/cache/messages.txt cache file.
#     https://www.dokuwiki.org/update_check