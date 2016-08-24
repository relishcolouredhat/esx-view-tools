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


function scrape-vidata {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline)]
        [object[]]$obj
        )
    Process {
        write-verbose 'grabbing state of '
        $flagstate = 1 # 1 - Green, 2 - Yellow, 3 - Red (0 reserved for future use)
        $flag = 'red'
        $pwrstate = $_.powerstate
        $ahostname = 'NULL'
        $aguest = $_ | Get-VMGuest
        $ahost = $_ | Get-VMHost
        $ahostname = $aguest.hostname
        $ipaddr = $aguest.IPAddress[0]
        $flagreason = ''
        $ahoststate = $ahost.ConnectionState
        $os = $aguest.OSFullName
        
        

        if ($pwrstate -eq 'PoweredOn') {$flag = 'green'}
        if ($pwrstate -eq 'Suspended') {
            $flag = 'yellow'
            $flagreason = 'powerstate-suspended'
            $flagstate = 2
            }
        if (!$ipaddr) {
            $flag = 'yellow'
            $flagreason='no-guest-ip'
            $flagstate = 2
            }
        if ($pwrstate -eq 'PoweredOff') {
            $flag = 'red'
            $flagreason = 'pwroff-svr'
            $flagstate = 3
            }
        if ($cpup1 -gt 90) {
            $flag = 'red'
            $flagreason = 'CPU-USE'   
            $flagstate = 3
            }
        if ($flagstate -lt 3){ #properties that only exist in an active vm
            $cpup1 = ($_ | get-stat -stat cpu.usage.average -maxsamples 1).value.toint16($_)
            $cpuhz1 = $_ | get-stat -stat cpu.usagemhz.average -maxsamples 1
            if ($ipaddr) {$rtt = (test-connection $ipaddr -count 1).responsetime} 
            if (!$ipaddr) {$rtt = '!!!'}
            }
        else{ #properties to set based upon the assumption a vm is inactive (mostly to allow sorting to work properly)
            $cpup1 = 0
            #$ipaddr = 'OFF'
            $cphhz1 = (0)
            }
        if ($cpuhz1 -eq $null) {$cpuhz1 = (0)}


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
        $line | add-member -type NoteProperty -name cpup1 -value $cpup1
        $line | add-member -type noteproperty -name cpuhz1 -value $cpuhz1[0]
        $line | add-member -type NoteProperty -name flagstate -value $flagstate
        $line | add-member -type NoteProperty -name '%' -value '%'
        $line | add-member -type NoteProperty -name 'Mhz' -value 'Mhz'
        #flag reason property

        $line
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

#$spinner = ('|','/','-','\')

$firstrun = $true

function work {
    write-verbose 'starting workerbee 0.5'
    #write-host "firstrun: $firstrun"
    $columns = @{'property'='flag', 'pwrstate', 'guest', 'ip', 'rtt', 'flagreason', 'cpup1','%', 'cpuhz1', 'Mhz'}
    #take input vm's > grab data from them > sort by poperty > grab above columns | format in a table autosized and wrapped when needed > 
    $vms | scrape-vidata | sort cpup1 -Descending | select @columns | format-table -autosize -wrap | out-string | fromstring-colourize
    $refresh = 5
    $i = $refresh
    while ($i -gt 0 ) {
        $i--
        #write-progress -activity 'waiting to refresh' -PercentComplete ((($refresh-$i)/$refresh)*100)
        #write-host "$i (($refresh-$i)/$refresh) "
        if (!$firstrun) {write-host "`b"-nonewline}
        #write-host $spinner[$i] -nonewline
        Write-Host '.' -NoNewline
        sleep -milliseconds 1000
        #set-variable -name firstrun -value $false -scope global
        #write-host $firstrun
        }
     
    }

write-host 'all functions loaded fresh'
write-host 'Methods 0.2-1'
