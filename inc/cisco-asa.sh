################################################################################
##
## Function for Cisco ASA Firewalls
##
## This file is part of saveconfig.
##
## License : EUROPEAN UNION PUBLIC LICENCE v. 1.2
##
## 2017-10-28    str     modularization of code
##
################################################################################
proc cisco_asa { IPV4 NAME USERNAME PASSWORD ENABLE} {
    #
    # Import global variables into function
    #
    global DEVICE
    global COPYSCP
    global LOCALTFTP
    global TODAY
    global YESTERDAY
    # Import global color lines
    global colDefault
    global colBegin
    global colCompleted
    global colSkipped
    global colFailed
    global colSuccess
    #
    # Execute the device commands with error handling
    #
    if { [catch {
        spawn ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $USERNAME@$IPV4
        expect "assword:"     { send "$PASSWORD\n" }
        if { $ENABLE!="" }    { expect ">" { send "enable\n" } expect "assword:" { send "$ENABLE\n" } }
        expect "#"            { send "conf t\n" }
        expect "#"            { send "no banner exec\n" }
        expect "#"            { send "banner exec ^$TODAY - BACKUP DONE^\n" }
        expect "#"            { send "file prompt quiet\n" }
        expect "#"            { send "exit\n" }
        expect "#"            { send "wr mem\n" }
        expect "OK"           { send "copy run $COPYSCP/$DEVICE/$TODAY.$NAME.cfg\n\n\n" } 
        expect "copied"       { send "logout\n" }
        send_user "[exec date "+%Y-%m-%d %H:%M:%S"] saveconfig-backup: $colSuccess $NAME / $IPV4.\n"
    #
    # Catch errors
    #
    } errorid] } {
        send_user "[exec date "+%Y-%m-%d %H:%M:%S"] saveconfig-backup: $colFailed $NAME / $IPV4.\n"
    }
    set status [catch {
        exec diff -y -W 200 --suppress-common-lines $LOCALTFTP/$DEVICE/$TODAY.$NAME.cfg \
        $LOCALTFTP/$DEVICE/$YESTERDAY.$NAME.cfg > $LOCALTFTP/$DEVICE/diff/$TODAY-$NAME.txt
    } result]
}
################################################################################
