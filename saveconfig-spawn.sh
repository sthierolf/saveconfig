#!/bin/bash
################################################################################
##
## saveconfig-spawn.sh
## --------------------
## Spawns saveconfig-backup.sh processes
##
## License : EUROPEAN UNION PUBLIC LICENCE v. 1.2
##
## 2017-10-28   str     re-writing and modularization of code
##
################################################################################
##
## GLOBAL-VARIABLES
## ----------------
## RCPT             Email recepient
## DEVICE()         Array with device types
## TODAY            Todays date
## TIMESTAMP        Timestamp for script
## ARCHIVEDATE      Archivedate 
##
################################################################################
RCPT="str"
DEVICE=(catalyst aironet ciscoasa ciscowlc)
TODAY=`date +%Y-%m-%d`
TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`
ARCHIVEDATE=`date +%Y-%m-%d -d "15 days ago"`
#
# Iterate through DEVICE() Array to start parallel saveconfig-backup processes
#
echo "$TIMESTAMP saveconfig-spawn: BEGIN parallel processes."
for i in "${DEVICE[@]}"
do
    { /srv/tftp/scripts/saveconfig/saveconfig-backup.sh $i & } 2>/dev/null;
    echo "$TIMESTAMP saveconfig-spawn: starting parallel process for: $i, pid:" $!
done
#
# wait for processes
#
for job in `jobs -p`
    do wait $job
done
echo "$TIMESTAMP saveconfig-spawn: COMPLETED processes completed."
#
# Concatenate log files
#
echo "$TIMESTAMP saveconfig-spawn: BEGIN concatenate logfiles."
for i in "${DEVICE[@]}"
do
    cat /srv/tftp/config/$i/log/$TODAY-$i.log >> /srv/tftp/temp/$TODAY-saveconfig-report.log
done
echo "$TIMESTAMP saveconfig-spawn: COMPLETED Concatenate logfiles."
#
# Send email report
#
echo "$TIMESTAMP saveconfig-spawn: BEGIN send email report."
countfailed=$(grep -i 'FAILED' /srv/tftp/temp/$TODAY-saveconfig-report.log | wc -l)
countsuccess=$(grep -i 'SUCCESS' /srv/tftp/temp/$TODAY-saveconfig-report.log | wc -l)

mailx -s "Daily Backup Report ($TODAY)" $RCPT <<ENDOFMAIL
Hi,
This is the email with the Daily Backup Report.

My Report summary:
FAILED: $countfailed
SUCCESS: $countsuccess

Backup, log and diff files:
See details in /srv/tftp/config
Thank you
ENDOFMAIL
rm /srv/tftp/temp/$TODAY-saveconfig-report.log
echo "$TIMESTAMP saveconfig-spawn: COMPLETED send email report."
#
# Archiving and cleanup
#
echo "$TIMESTAMP saveconfig-spawn: BEGIN archiving $ARCHIVEDATE."
mkdir /srv/tftp/archive/$ARCHIVEDATE 2> /dev/null
for i in "${DEVICE[@]}"
do
    mv /srv/tftp/config/$i/$ARCHIVEDATE* /srv/tftp/temp/ 2> /dev/null
    mv /srv/tftp/config/$i/diff/$ARCHIVEDATE* /srv/tftp/temp/ 2> /dev/null
    mv /srv/tftp/config/$i/log/$ARCHIVEDATE* /srv/tftp/temp/ 2> /dev/null
    tar -cf /srv/tftp/archive/$ARCHIVEDATE/$ARCHIVEDATE.$i.tar /srv/tftp/temp/* 2> /dev/null
    gzip -9 -f /srv/tftp/archive/$ARCHIVEDATE/$ARCHIVEDATE.$i.tar 2> /dev/null
    rm /srv/tftp/temp/* 2> /dev/null
done
echo "$TIMESTAMP saveconfig-spawn: COMPLETED archiving $ARCHIVEDATE."
