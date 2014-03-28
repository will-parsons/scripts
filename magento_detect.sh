#! /bin/bash
# Script to detect Magento instances. Uses the 'locate' database.
# will.parsons@rackspace.co.uk

DOCROOTS=""
if [[ -f /var/lib/mlocate/mlocate.db ]]; then 
    DOCROOTS=$(/usr/bin/locate app/Mage.php | sed 's/\/app\/Mage.php//g');
else
    exit 1
fi

EDITION=""
VERS=""
URL=""

OUTPUT=""

for root in $DOCROOTS; do
    cd $root
    
    if [[ -d app/code/core/Enterprise ]]; then 
        EDITION="Enterprise"
     else
        EDITION="Community"
    fi
    
    VERS=$(echo "include 'app/Mage.php'; echo Mage::getVersion();" | php -a -d "safe_mode=Off" 2>/dev/null | egrep -o '[1-9].*')

    URL=$(echo  "include 'app/Mage.php';  echo Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB);" | php -a -d "safe_mode=Off" 2>/dev/null | egrep -o 'http.*')

    OUTPUT="$OUTPUT$EDITION,$VERS,$URL\n"
done

echo -e $OUTPUT | sort | uniq | grep -v localhost

# Tidy up
rm -f /home/rack/magento_detect.sh
