##########################################
### This document is the exclusive property
### of the Packet Badger Technology Corporation
### All Rights Reserverved 2016
### No warranty is implied as this document is for internal use only
### Author: Kelsey R. Comstock
##########################################

 
$sourcedir = $myinvocation.mycommand | split-path

write-verbose "Called path detected as $sourcedir"

$sourcefile = 'esx-view-tools.ps1'
$source = "$sourcedir\$sourcefile"

write-verbose "Loading $sourcefile from dir $sourcedir..."

$refreshmethods = 2 #time in whole seconds betwen checks for new display settings
$looptime = $refreshmethods

#$dir = get-content .\local.cfg
#$file = 'esx-view-tools.ps1'
 
. "$source"

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
        . "$sourcedir\$sourcefile"
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