#! /bin/bash

# author: will parsons
# version: 0.1
#
# Script to crawl a site, warm up the cache, and log the results.
# Logs to current directory, with a list of URLs which could be used for "siege -i" for load testing.
#
# Originally for Magento, but could be adapted for other CMS. Note egrep -v for exclusions.
#
# If running from cron, be sure to change the log location or rotate it.
#
# Please be sensible with this script, it will hit every URL on a site three times,
# and could be seen as a DoS if used without site owner's permission.
#
#

if [ "x$1" = "x" ]; then
    echo "usage: $0 <hostname>"
    exit 1
fi


BASE=$1
LOGDIR="."

LOG=$LOGDIR/warmup_$1_$(date +"%Y%m%d_%H%M").log
touch $LOG

# Delete logs older than a week
PREVLOGS=$(find $LOGDIR -type f -name "warmup_$1_*" -mtime +7)
rm -f $PREVLOGS



# Recursive function to curl a URLS, grap all links, and curl each of them.
function crawl() {
    # Already logged, stop recursion
    if egrep -q '$1/?$' $LOG; then
        return 1
    else
    
    # Output to terminal
    echo $1
    
    # Hit three times to really make sure it's cached at every level.
    curl -s -o /dev/null $1
    curl -s -o /dev/null $1
    # Use the third hit to grep for URLs to hit next. Optimised for Magento source output.
    # The exceptions are to prevent overuse, tag clouds and the like can end up cause enless unique URLs.
    # Note: the grep ^http://$BASE is what keeps to this website. Otherwise you'll probably curl the whole internet.
    LIST=$(curl -s $1 | egrep -o 'href="[^"^\?]*"' | cut -d'"' -f2 | grep ^http://$BASE | egrep -v 'login|checkout|media|comments|blog|feed|account|uenc|review-form|sendfriend|wishlist|tag|price|filter|wp|\/l\/')
    # Log it, so we can skip it next time.
    echo $1 >> $LOG

    # Here's the recursion, with another check to avoid infinite loops.
    for i in $LIST; do
        if egrep -q "$i/?$" $LOG; then
            continue
        else
            crawl $i
        fi
    done 

fi

}

# First curl, will only start crawling if that works.
curl -I $BASE && crawl $BASE

