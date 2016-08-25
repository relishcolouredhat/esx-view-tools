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

$loadermajor = "0.2"
$loaderminor = "1"
$global:pbtc_display_loaderver = "$loadermajor-$loaderminor"

function primaryloop {
    while ($true){
        while ($looptime -gt 0){
            work
            write-host "LV:$pbtc_display_loaderver/T:$looptime"
            $looptime--
            }
        . "$dir\$file"
        $looptime = $refreshmethods
        }
    }


primaryloop

<#
function run-in-ide { #use to run in IDE since $dir will fail
    $dir = 'D:\packetbadger\esx-view-tools'#enter directory here. duh.
    primaryloop
    }

run-in-ide

#>