##########################################
### This document is the exclusive property
### of the Packet Badger Technology Corporation
### All Rights Reserverved 2016
### No warranty is implied as this document is for internal use only
### Author: Kelsey R. Comstock
##########################################



$refreshmethods = 2 #time in whole seconds betwen checks for new display settings
$looptime = $refreshmethods
$dir = get-content .\local.conf
$file = 'esx-view-tools.ps1'
 
. "$dir\$file"


function primaryloop {
    while ($true){
        while ($looptime -gt 0){
            work
            $looptime--
            write-host "looptime: $looptime"
            }
        . "$dir\$file"
        $looptime = $refreshmethods
        }
    }


primaryloop

