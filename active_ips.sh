#! /bin/bash
# Script to count access log entries for login / cart activity.
# For determining how many Magento visitors actually interact with the website.

# REGEX: What we are looking for. Tweak as nexessary
REGEX="checkout/cart/add|/customer/account/loginPost|/wishlist"

# EXCLUDE: What we want to exclude.
EXCLUDE="admin|app/etc/local.xml|api/soap"


if [ $# -eq 0 ]
  then
    echo "Usage: $0 logfile(s)

e.g. $0 access_log*
"
   exit 1
fi


UNIQ_IP=$(cat $@  | awk '{print $1}' | cut -d',' -f1 | egrep -v "^\:\:1|^127|^192\.168" | sort | uniq)
ACTIVE_USERS=$(cat $@ | egrep $REGEX | egrep -v $EXCLUDE |  awk '{print $1}' | sort | uniq)

UNIQUE_COUNT=$(echo "$UNIQ_IP" | wc -l)
ACTIVE_COUNT=$(echo "$ACTIVE_USERS" | wc -l)

PERCENT_ACTIVE=$(echo "scale=1; $ACTIVE_COUNT*100/$UNIQUE_COUNT" | bc)
PERCENT_BROWSING=$(echo "scale=1; 100-$PERCENT_ACTIVE" | bc)

echo -e "\n\nOf the entries in $@ :\n"

echo "$PERCENT_ACTIVE% were active and interacted with the site."
echo "$PERCENT_BROWSING% were just browsing, or window shopping, and ought to be served from cache."
echo ""
echo "Total active IPs: $ACTIVE_COUNT"
echo "Total unique IPs: $UNIQUE_COUNT"
echo ""
echo "REGEX was \"$REGEX\" "
echo "excluding \"$EXCLUDE\" "

#echo "DEBUG:"
#cat $@ | egrep $REGEX | egrep -v $EXCLUDE
