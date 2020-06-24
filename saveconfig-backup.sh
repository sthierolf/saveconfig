#!/usr/bin/expect
################################################################################
##
## saveconfig-backup.sh
## --------------------
## Saves text-based configuration files. Currently supports:
## - Cisco Catalyst Switches
## - Cisco Aironet Standalone Access Points
## - Cisco Wireless LAN Controller
## - Cisco ASA Firewall
##
## Requires CSV file in the format: ipv4;hostname;type;username;password;enable
## 
## License : EUROPEAN UNION PUBLIC LICENCE v. 1.2
##
## 2017-10-28   str     re-writing and modularization of code
##
################################################################################
##
## GLOBAL-VARIABLES
## ----------------
## DEVICE            Device-Prefix as command line argument
## COPYTFTP          The path to your TFTP server for the device
## COPYSCP           The path to your SCP server for the device
## LOCALTFTP         The path on your server for the configs
## INPUTPATH         The path on your server for the scripts
## TODAY             Get today's date in ISO format
## YESTERDAY         Calculate yesterday's date in ISO format
##
################################################################################
set DEVICE [lindex $argv 0]
set COPYSCP "scp://saveconfig:saveconfig@172.30.100.202//srv/tftp/config"
set LOCALTFTP "/srv/tftp/config"
set INPUTPATH "/srv/tftp/scripts/saveconfig/"
set TODAY [exec date "+%Y-%m-%d"]
set YESTERDAY [exec date --date "-1 day" "+%Y-%m-%d"]
set timeout 15
set SCRIPTNAME [info script]
# log_user          Expect's log_user command. 0 = no output, 1 = output
# log_file          Expect's log_file command.
log_user 0
log_file -noappend $LOCALTFTP/$DEVICE/log/$TODAY-$DEVICE.log
#
# Define colored lines
#
set colDefault "\033\[0;39m"
set colBegin "\033\[0;96mBEGIN\033\[0;39m"
set colCompleted "\033\[0;96mCOMPLETED\033\[0;39m"
set colSkipped "\033\[0;96mSKIPPED\033\[0;39m"
set colFailed "\033\[0;31mFAILED\033\[0;39m" 
set colSuccess "\033\[0;32mSUCCESS\033\[0;39m"
#
# Include device specific functions
#
source [file join [file dirname $SCRIPTNAME] inc/cisco-catalyst.sh]
source [file join [file dirname $SCRIPTNAME] inc/cisco-aironet.sh]
source [file join [file dirname $SCRIPTNAME] inc/cisco-asa.sh]
source [file join [file dirname $SCRIPTNAME] inc/cisco-wlc.sh]
#
# Starting backup
#
send_user "[exec date "+%Y-%m-%d %H:%M:%S"] saveconfig-backup: $colBegin $DEVICE.\n"
#
# Open CSV files
#
if { [catch {
    set fileid [open $INPUTPATH/$DEVICE.csv]
    set content [read $fileid]
close $fileid
#
# Catch errors
#
} errorid]
} {
    send_user "[exec date "+%Y-%m-%d %H:%M:%S"] saveconfig-backup: $colFailed, cannot open file: $INPUTPATH/$DEVICE.csv.\n"
}
#
# Determine device type from CSV and start the proper function
#
if { [catch {
    # split into line numbers
    set hosts [split $content "\n"]
    # iterate through lines
    foreach rec $hosts {
        # split lines with ; into data
        set fields [split $rec ";"]
        # and assign variables
        lassign $fields ipv4 name type username password enable
        # determine device type and start backup job function
        if {$type == "catalyst"} {
            set running [cisco_catalyst $ipv4 $name $username $password $enable]
        }
        if {$type == "aironet"} {
            set running [cisco_aironet $ipv4 $name $username $password $enable]
        }
        if {$type == "ciscoasa"} {
            set running [cisco_asa $ipv4 $name $username $password $enable]
        }
        if {$type == "ciscowlc"} {
            set running [cisco_wlc $ipv4 $name $username $password $enable]
        }
    }
#
# Catch errors
#
} errorid]
} {
    send_user "[exec date "+%Y-%m-%d %H:%M:%S"] saveconfig-backup: $colFailed, cannot parse file: $INPUTPATH/$DEVICE.csv.\n"
}
#
# Ending backup
#
send_user "[exec date "+%Y-%m-%d %H:%M:%S"] saveconfig-backup: $colCompleted $DEVICE.\n"
