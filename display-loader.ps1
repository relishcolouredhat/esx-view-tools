##########################################
### This document is the exclusive property
### of the Packet Badger Technology Corporation
### All Rights Reserverved 2016
### No warranty is implied as this document is for internal use only
### Author: Kelsey R. Comstock
##########################################



$refreshmethods = 3 #time in whole seconds betwen checks for new display settings
$looptime = $refreshmethods

. "C:\esxiso\esx-view-tools.ps1"


function primaryloop {
    while ($true){
        while ($looptime -gt 0){
            work
            $looptime--
            write-host "looptime: $looptime"
            }
        . "C:\esxiso\esx-view-tools.ps1"
        $looptime = $refreshmethods
        }
    }

$MyInvocation

primaryloop

