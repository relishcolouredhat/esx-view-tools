 ##########################################
### This document is the exclusive property
### of the Packet Badger Technology Corporation
### All Rights Reserverved 2016
### No warranty is implied as this document is for internal use only
### Author: Kelsey R. Comstock
##########################################


################
#
#
#roadmap question: how to / should you alarm on a deleted VM? (default, yes IMHO as only production servers would be piped into
#    the work functon.   
#
#
#


$loadvalue = 0

#Write-Progress -Activity 'Loading Modules' -Status 'Loading powerCLI snapin' -PercentComplete $loadvalue

$verbosepreference = 2

$host.ui.RawUI.WindowTitle = 'loading PowerCLI'

Add-PSSnapin vmware.vimautomation.core -ea "silentlycontinue"

$loadvalue = 25

#Write-Progress -Activity 'Loading Modules' -Status 'Connecting to vCenter' -PercentComplete $loadvalue

$server = '192.168.86.199'

if (!$defaultviserver.IsConnected){
    write-verbose "Conencting to $server"
    connect-viserver $server
    }

$loadvalue = 50

#Write-Progress -Activity 'Loading Modules' -Status 'getting vms...' -PercentComplete $loadvalue

$vms =  get-vm
$loadvalue = 75
#Write-Progress -Activity 'Loading Modules' -Status 'getting all vms...' -PercentComplete $loadvalue
#$vmguests = get-vm | Get-VMGuest
$loadvalue = 100
#Write-Progress -Activity 'Loading Modules' -Status 'Loading Modules' -PercentComplete $loadvalue

$verbosepreference = 0

$host.ui.RawUI.WindowTitle = "NOC WATCHKEEPER ALPHA 1"

function test-object {
    [cmdletbinding()] 
    Param ( 
        [parameter(ValueFromPipeline)]
        [int[]]$Integer
        )
    Process {
        $_
        }
    }


$numberOfVM = $vms.Length

function scrape-vidata {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline)]
        [object[]]$obj
        )
    Begin {
        $i = 0
        $scrapeStartTime = get-date
        write-host "Last run took $scrapespan seconds for $numberOfVM VM's"
        }
    Process {
        $i++
        write-host "($i/$numberOfVM)"
        $flagstate = 1 # 1 - Green, 2 - Yellow, 3 - Red (0 reserved for future use)
        $flag = 'red'
        $pwrstate = $_.powerstate
        $ahostname = 'NULL'
        
        $aguest = $_ | Get-VMGuest 
        $ahost = $_ | Get-VMHost 

        if ($pwrstate -ne 'PoweredOff') {$vmstats = $_ | get-stat -common -maxsamples 1}
        
        $ahostname = $aguest.hostname
        $ipaddr = $aguest.IPAddress[0]
        $flagreason = ''
        $ahoststate = $ahost.ConnectionState
        $os = $aguest.OSFullName
        $vmver = $_.version
        

        if ($pwrstate -eq 'PoweredOn') {$flag = 'green'}
        if ($pwrstate -eq 'Suspended') { #handles 'suspended' power state
            $flag = 'yellow'
            $flagreason = 'pwr-suspended'
            $flagstate = 2
            }
        if (!$ipaddr) { #handles lack of IP address
            $flag = 'yellow'
            $flagreason='no-guest-ip'
            $flagstate = 2
            }
        if ($pwrstate -eq 'PoweredOff') {
            $flag = 'red'
            $flagreason = 'pwroff-svr'
            $flagstate = 3
            }

        if ($flagstate -lt 3){ #properties that only exist in an active vm
            #$vmstats = $_ | get-stat -common -MaxSamples 1 #pulls common statistcs object for an active vm
            $cpup = $vmstats[8].value #may be setup for v11 vm if it fails on other vm versions
            $cpuhz = $vmstats[7].value

            #$cpup1datum = $_ | get-stat -stat cpu.usage.average -maxsamples 1
            #$cpup1 = $cpup1datum.value.toint16()
            #$cpuhz1 = $_ | get-stat -stat cpu.usagemhz.average -maxsamples 1
            if ($ipaddr) {$rtt = (test-connection $ipaddr -count 1).responsetime} 
            if (!$ipaddr) {$rtt = '???'}
            }
        if ($flagstate -eq 3){ #properties to set based upon the assumption a vm is inactive (mostly to allow sorting to work properly)
            $cpup = 0
            #$ipaddr = 'OFF'
            $cpuhz = 0
            }
        if ($cpuhz -eq $null) {$cpuhz = 0}
        if ($cpup -gt 90) {
            $flag = 'red'
            $flagreason = 'CPU-USE'   
            $flagstate = 3
            }
        if ($pwrstate -eq 'PoweredOff') { #second power off rule to increase predictability of display (pwroff will always be ultimate reason for off server)
            $flagreason = 'pwroff-svr'
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
        $line | add-member -type NoteProperty -name '%' -value '%'
        $line | add-member -type NoteProperty -name 'Mhz' -value 'Mhz'
        #flag reason property

        $line
        }
    End {
        $scrapeEndTime = get-date
        $global:scrapespan = ($scrapeEndTime - $scrapeStartTime).seconds
        write-host "Got $numberOfVm VM's in $global:scrapespan"
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





<#
new-object displayline -Property @{
    $hostname = get-
    

    
} #>


 
$methodmajor = '0.2'
$methodminor = '1f'   
$methodver = "$methodmajor-$methodminor"

function work {
    write-verbose 'starting workerbee 0.5'
    #write-host "firstrun: $firstrun"
    $columns = @{'property'='flag', 'pwrstate', 'guest', 'ip', 'rtt', 'flagreason', 'cpup','%', 'cpuhz', 'Mhz'}
    #take input vm's > grab data from them > sort by poperty > grab above columns | format in a table autosized and wrapped when needed > 
    $vms | scrape-vidata | sort cpup -Descending | select @columns | format-table -autosize -wrap | out-string | fromstring-colourize
    $refresh = 2
    $i = $refresh
    write-host $methodver -nonewline
    while ($i -gt 0 ) {
        $i--
        Write-Host "." -NoNewline
        sleep -milliseconds 1000
        }
     
    }


write-host 'all functions loaded fresh'
write-host "Methods:$methodver"
