 ##########################################
### This document is the exclusive property
### of the Packet Badger Technology Corporation
### All Rights Reserverved 2016!
### No warranty is implied as this document is for internal use only
### Author: Kelsey R. Comstock
##########################################
$methodmajor = '0.2'
$methodminor = '3a'   
$methodver = "vtBuild:$methodmajor-$methodminor //"
#
# Feature Roadmap:
#
# Near Horizion.
#
# Pull vm version, add to monitored 
#
# Setup colour module for structured input
#
# 
# 
#

#$verbosepreference = 0 #verbose preference for pre-powerCLI snapins

$host.ui.RawUI.WindowTitle = 'loading PowerCLI'

Add-PSSnapin vmware.vimautomation.core -ea "silentlycontinue"

$server = '192.168.86.199'

$host.ui.RawUI.WindowTitle = 'Checking for vCentre Connection...'

if (!$defaultviserver.IsConnected){
    $host.ui.RawUI.WindowTitle = 'Connecting to $server...'    
    write-verbose "Conencting to $server"
    connect-viserver $server
    }




$vms =  get-vm

#$vmguests = get-vm | Get-VMGuest

#$verbosepreference = 2 #verbose-preference to get 

$host.ui.RawUI.WindowTitle = "NOC WATCHKEEPER ALPHA                         $methodver LV:$global:pbtc_display_loaderver"
$numberOfVM = $vms.Length
#$scrapespan = 1 #init to prevent 'devide by zero' error on first VM PER SECOND calc

function scrape-vidata {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline)]
        [object[]]$obj
        )
    Begin {
        #$verbosepreference = 2 #uncomment for verbose scraper output
        $i = 0
        $scrapeStartTime = get-date #timestamp for start of scrape time
        write-verbose "Last run took $scrapespan seconds for $numberOfVM VM's" #duration of last runtime
        $pbarline = '_'*($numberofvm-($numberofvm.Tostring($_).length)) #line for progress bar, shorter to fit numbers on sides
        $pbarlong = '_'*$numberofvm #line as many chars long as the number of vms
        $vmps = [math]::round($numberOfVM / $scrapespan,3) #number of vm's per second
        $pbarfull = "1$pbarline$numberOfVM [EST $scrapespan`s refresh @ $vmps` vmps]" #Progressbar for display
        write-host $pbarfull
        }
    Process {
        $i++
        write-verbose "Loading VM:($i/$numberOfVM)"
        write-debug "Loading VM: $_.guest"
        write-host '.'-NoNewline
        $flagstate = 1 # 1 - Green, 2 - Yellow, 3 - Red (0 reserved for future use)
        $flag = 'red'
        $pwrstate = $_.powerstate
        $ahostname = 'NULL'


        
        #
        # Lines below are the calls to the VMWare API (PowerCLI). They Are the reasonably
        # slow, and are very chatty when $verboseprefernece is not set to 0. Comment out
        # the line if you need to troubleshoot the calls to PowerCLI
        # 
        # This is the purpose of the following line.
        #
        #$verbosepreference = 0 # <<---- COMMENT OUT FOR POWER CLI VERBOSITY 
        #
        #
        #
        $aguest = $_ | Get-VMGuest 
        $ahost = $_ | Get-VMHost
        $vmver = $_.version

        if ($vmver -eq 'v11') { #version 11 vm get-stat pattern, tested       
            write-debug 'v11 vm detected, using v11 get-stat -common fixed data pattern'
            if ($pwrstate -ne 'PoweredOff') {$vmstats = $_ | get-stat -common -maxsamples 1}
            else {$vmstats = $null}
            }

        else{ #catchall - both do same thing, for future use if other vm versions do not match
            write-debug 'non-v11 vm detected, still using v11 fixed data pattern'
            if ($pwrstate -ne 'PoweredOff') {$vmstats = $_ | get-stat -common -maxsamples 1}
            else {$vmstats = $null}
            }
        #
        #
        #
        #$verbosepreference = 2# <<---- REVERSE OF ABOVE CALL TO REMOVE CLI VERBOSITY
        #                       <<<<<< CHANGE THIS TO A CALL TO THE STATE PRIOR TO 
        #                       <<<<<< TOGGLE ABOVE. 
        #
        #


        $ahostname = $aguest.hostname
        $ipaddr = $aguest.IPAddress[0]
        $flagreason = ''
        $ahoststate = $ahost.ConnectionState
        $os = $aguest.OSFullName
        
        

        if ($pwrstate -eq 'PoweredOn') {$flag = 'green'}
        if ($pwrstate -eq 'Suspended') { #handles 'suspended' power state
            $flag = 'yellow'
            $flagreason = 'pwr-suspended'
            $flagstate = 2
            }
        if (!$ipaddr) { #handles lack of IP address
            $flag = 'yellow'
            $flagreason='[noVMtools?]'
            $flagstate = 2
            }
        if ($pwrstate -eq 'PoweredOff') {
            $flag = 'red'
            $flagreason = 'pwroff-svr'
            $flagstate = 3
            }

        if ($flagstate -lt 3){ #properties that only exist in an active vm
        <#
            if ($vmver -eq 'v7' -or $vmver -eq 'v8' -or $vmver -eq 'v9'){ 
                $cpuhzdata = $vmstats[7]
                $cpudata = $vmstats[8] 
                }            
            if ($vmver -eq 'v11'){
                $cpuhzdata = $vmstats[8]
                $cpudata = $vmstats[11]
                }
        #>

            $cpudata = $vmstats | where {$_.metricID -match 'cpu.usage.average'}
            $cpuhzdata = $vmstats | where {$_.metricId -match 'cpu.usagemhz.average' -and $_.instance -eq ''}



            $cpuval = $cpudata.value
            $cpuunit = $cpudata.unit
            $cpuhzval = $cpuhzdata.value
            $cpuhzunit = $cpuhzdata.unit
            $cpup = "$cpuval$cpuunit"
            $cpuhz = "$cpuhzval$cpuhzunit" 



            #$cpup1datum = $_ | get-stat -stat cpu.usage.average -maxsamples 1
            #$cpup1 = $cpup1datum.value.toint16()
            #$cpuhz1 = $_ | get-stat -stat cpu.usagemhz.average -maxsamples 1
            if ($ipaddr) {$rtt = (test-connection $ipaddr -count 1).responsetime} 
            if (!$ipaddr) {$rtt = '???'}
            }
        if ($flagstate -eq 3){ #properties to set based upon the assumption a vm is inactive (mostly to allow sorting to work properly)
            $cpup = 0
            #do not set ip address to 'OFF' - you will try and ping it ;)
            $cpuhz = 0
            }
        if ($cpuhz -eq $null) {$cpuhz = 0}
        if ($cpup -gt 90) {
            $flag = 'red'
            $flagreason = '[CPU>90%]'   
            $flagstate = 3
            }
        if ($pwrstate -eq 'PoweredOff') { #second power off rule to increase predictability of display (pwroff will always be ultimate reason for off server)
            $flagreason = '[pwroff]'
            $flagstate = 3
            }
             
        
        $line = new-object System.Object
        $line | add-member -type noteProperty -name flag -value $flag
        $line | add-member -type noteProperty -name pwrstate -value $pwrstate
        $line | add-member -type noteProperty -name hostname -value $hostname
        $line | add-member -type noteProperty -name guest -value $aguest 
        $line | Add-member -type noteproperty -name host -value $ahostname
        $line | add-member -type noteProperty -name ip -value $ipaddr
        $line | add-member -type noteProperty -name hoststate -value $ahoststate
        $line | add-member -type noteProperty -name os -value $ipaddr
        $line | add-member -type noteProperty -name rtt -value $rtt
        $line | add-member -type NoteProperty -name flagreason -value $flagreason
        $line | add-member -type NoteProperty -name cpup -value $cpup
        $line | add-member -type noteproperty -name cpuhz -value $cpuhz
        $line | add-member -type NoteProperty -name flagstate -value $flagstate
        $line | add-member -type NoteProperty -name vmVer -value $vmver

        #flag reason property

        $line
        }
    End {
        $scrapeEndTime = get-date
        $global:scrapespan = ($scrapeEndTime - $scrapeStartTime).seconds
        write-host "Got $numberOfVm VM's in $global:scrapespan"
        $vmstats = $null
    }
    } 

$fg = @{object='apple!';foregroundcolor='green';backgroundcolor='darkgreen'}



function fromstring-colourize {
    [cmdletbinding()] #causes function to be treated as a cmdlet within powershell
    Param (
        [parameter(ValueFromPipeline)]
        $obj
        )
    Process {
        $page =  out-string -InputObject $obj

        $outpage = $page.split([environment]::Newline)
        clear
        write-host 
        write-host $methodver
        foreach ($line in $outpage){
                if ($line.equals('')){continue} #catch and remove blanklines (generate real blanklines with a space)
                if ($line.contains('green')){ write-host $line -foregroundcolor green -backgroundcolor darkgreen}              
                elseif ($line.contains('yellow')){write-host $line -foregroundcolor yellow -backgroundcolor darkgray}
                elseif ($line.contains('red')){write-host $line -foregroundcolor yellow -backgroundcolor red}
                else {write-host $line -ForegroundColor darkgray -BackgroundColor blue}
                }
    }
}

function write-colour {
    [cmdletbinding()] #causes function to be treated as a cmdlet within powershell
    Param([object]$line)
    Begin{}
    Process{}
    End{}
}




function work {
    write-verbose 'starting workerbee 0.5'
    #write-host "firstrun: $firstrun"
    $columns = @{'property'='flag', 'pwrstate', 'guest', 'ip', 'rtt', 'flagreason', 'cpup', 'cpuhz','vmVer'}
    #take input vm's > grab data from them > sort by poperty > grab above columns | format in a table autosized and wrapped when needed > 
    $verbosepreference = 0
    $vms | scrape-vidata | sort cpup -Descending | select @columns | format-table -autosize | out-string | fromstring-colourize
    $refresh = 0
    $i = $refresh
    #write-host $methodver -nonewline
    while ($i -gt 0 ) {
        $i--
        Write-Host "." -NoNewline
        sleep -milliseconds 1000
        }
     
    }


write-host 'all functions loaded fresh'
write-host "Methods:$methodver"