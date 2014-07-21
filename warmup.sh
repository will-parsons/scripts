#! /bin/bash

# author: will parsons
# version: 0.2
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

BASE=$1
LOGDIR="."

# Avoid cron jobs piling up
PROCESS_LIMIT=10

# Quick way to avoid really long or cyclical paths, like
# http://example.com/store/catalog/product/view/id/1234/x/some-product-name/category/123/
MAX_PATH_DEPTH=8

if [ "x$1" = "x" ]; then
    echo "usage: $0 <hostname>"
    exit 1
fi



LOG=$LOGDIR/warmup_$1_$(date +"%Y%m%d_%H%M").log
touch $LOG

# Delete logs older than a week
PREVLOGS=$(find $LOGDIR -type f -name "warmup_*" -mtime +7)
rm -f $PREVLOGS



# Recursive function to curl a URLS, grap all links, and curl each of them.
function crawl() {
    # Already logged, stop recursion
    if egrep -q '$1/?$' $LOG; then
        return 1
    else
    
    # Output to terminal
    echo $1
    
    # If you are normalizing User Agents in Varnish, you might want to hit with other UAs first.
    # curl -s -o /dev/null -A "iPhone" $1
    # curl -s -o /dev/null -A "iPad"   $1 
    
    # Curl the URL then grep for URLs to hit next. Optimised for Magento source output.
    # The exceptions are to prevent overuse, tag clouds and the like can end up cause enless unique URLs.
    # Note: the grep ^http://$BASE is what keeps to this website. Otherwise you'll probably curl the whole internet.
    LIST=$(curl -s -A "Mozilla/5.0 (https://github.com/will-parsons/scripts/blob/master/warmup.sh)" $1 | egrep -o 'href="[^"^\?]*"' | cut -d'"' -f2 | grep ^http://$BASE | egrep -v 'login|checkout|media|image|gallery|comments|blog|feed|account|uenc|review-form|sendfriend|wishlist|tag|price|filter|wp|\/l\/')
    # Log it, so we can skip it next time.
    echo $1 >> $LOG

    # Here's the recursion, with check for infinite loops (logged already?) and path depth
    for i in $LIST; do
        # Count the slashes, allowing one at the end and two for http://
        PATH_DEPTH=$(echo "$(tr -dc '/' <<<"$i" | wc -c) - 3" | bc)

        if egrep -q "$i/?$" $LOG; then
            # Already seen it
            continue
        elif [ $PATH_DEPTH -gt $MAX_PATH_DEPTH ]; then
            # Path too deep, skip
            continue
        else
            crawl $i
        fi
    done

fi

}

# First curl, will only start crawling if that works.
curl -I $BASE && crawl $BASE

