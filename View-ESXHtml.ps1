 ##########################################
### This document is the exclusive property
### of the Packet Badger Technology Corporation
### All Rights Reserverved 2016
### No warranty is implied as this document is for internal use only
### Author: Kelsey R. Comstock
##########################################

#Fork suggestions by abe:  /reallbigabe
#CTRL-H'd write-host to Write-Output to output to file.  
#Since you made a bunch of ascii animation type stuff, will need to clean up and build a display() vs output

$methodmajor = '0.2'
$methodminor = '3a'   
$methodver = "vtBuild:$methodmajor-$methodminor //"

#Launch Parameters - Now requires dot-loading the script; 
#Should build name capability in, but breaks IP validation. 
#No certs on an IP - therefore not a valid TLS connection, mate. 

#Build default HTML header to inject CSS - allow passing of custom HTML from the line though: 
$htmlhead = @'
<style type="text/css">
	.TFtable{
		width:90%; 
		border-collapse:collapse; 
	}
	.TFtable td{ 
		padding:7px; border:#4e95f4 1px solid;
	}
	/* Catering to ancient and Shitty browsers */
	.TFtable tr{
		background: #b8d1f3;
	}
	.TFtable tr:nth-child(odd){ 
		background: #b8d1f3;
	}
	.TFtable tr:nth-child(even){
		background: #dae5f4;
	}
</style>

<table class="TFtable">
'@

$htmlfoot = @'
</table>
'@


#Launch these bad boys on first launch to build the serializer into .NET to speed up powerCLI (particularly things like Get-VM)
#These addresses aren't formatted for launching from powershell

#Read it yo damn self:  http://blogs.vmware.com/PowerCLI/2011/06/how-to-speed-up-the-execution-of-the-first-powercli-cmdlet.html

#C:\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe install "VimService41.XmlSerializers, Version=4.1.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f";` 
#C:\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe install "VimService40.XmlSerializers, Version=4.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f";`
#C:\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe install "VimService25.XmlSerializers, Version=2.5.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f"

#IF OS is 64-bit, need the framework64 version AS WELL
#C:\Windows\Microsoft.NET\Framework64\v2.0.50727\ngen.exe install "VimService41.XmlSerializers, Version=4.1.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f";
#C:\Windows\Microsoft.NET\Framework64\v2.0.50727\ngen.exe install "VimService40.XmlSerializers, Version=4.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f";
#C:\Windows\Microsoft.NET\Framework64\v2.0.50727\ngen.exe install "VimService25.XmlSerializers, Version=2.5.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f"


#Give me params, baby
function View-ESXHtml
{
    [CmdletBinding()]
    Param
    (

		[ValidateScript({$_ -match [IPAddress]$_ })]  
        [string]
        $server = "192.168.86.199"
		,
		[string]
		$headhtml = $htmlhead
		,
		[string]
		$foothtml = $htmlfoot
		,
		[ValidateRange(0,2)]
		[int]
		$verbosepreference=0
        ,
		[String]
        $OutputPath = ".\ESX-Current.html"
		
    )

	
	
#
# I originally started modifying your tools script and then F-Bombed it into a second.  
# Probaby best to do the actual monitoring as an Engine - with an Onscreen and Outputted versions to
# avoid version / code drift

#

#dropped into launch params - but simply coding for -verbose and -debug is better.
#$verbosepreference = 0 #verbose preference for pre-powerCLI snapins

Write-Host 'loading PowerCLI'

Add-PSSnapin vmware.vimautomation.core -ea "silentlycontinue"

## Yuck.  Launch parameter...

#negated on launch params
#$server = '192.168.86.199'

Write-Host 'Checking for vCentre Connection...'

if (!$defaultviserver.IsConnected){
    Write-Host "Connecting to $server..."
    
    #M00t   
    #write-verbose "Conencting to $server"
    
    #ERror handling brua
    try {
	connect-viserver $server -ErrorAction Stop
		}
	catch{
	$server = Read-Host -Prompt "Give me a server I can actually connect to: "
	}
	finally {
	Write-Verbose "Can't run a connect-viserver without errors"
	Write-Output "You're hopeless."
	}
	

#Good place for a parameter filter :  Also - does Get-VM pass all properties in the object by default, or do you need to select?  You could
#probably also filter on the request side for properties you're not using - should speed up in a few hundred server environment	
$vms =  get-vm


#Derpy?
#$vmguests = get-vm | Get-VMGuest

#You can put this back... 
#$verbosepreference = 2 #verbose-preference to get 

$title = "NOC WATCHKEEPER ALPHA $methodver LV:$global:pbtc_display_loaderver"
$numberOfVM = $vms.Length
#$scrapespan = 1 #init to prevent 'devide by zero' error on first VM PER SECOND calc

#As I got to the bottom, I think your loops are inefficient - but I'm new to this too. 
# rather than a homemade i++ I think your function should be straightforward as you're already piping the stream to it. 
# a foreach ($vm in $vms) {} would probably be faster.

## LAst cof the night, its 1:!4 am and I need to be driving to the gym in 5 hours.  We'll work on this.  
#I very well may drop this into a solarwinds NOC view.  :D

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
        # Looks visual - Probably not needed for an HTML output
        #New acronym - LVPNTFHO... ok, that just become LV
        #LV 
        #$pbarline = '_'*($numberofvm-($numberofvm.Tostring($_).length)) #line for progress bar, shorter to fit numbers on sides
        #$pbarlong = '_'*$numberofvm #line as many chars long as the number of vms
        $vmps = [math]::round($numberOfVM / $scrapespan,3) #number of vm's per second
        #LV
        #$pbarfull = "1$pbarline$numberOfVM [EST $scrapespan`s refresh @ $vmps` vmps]" #Progressbar for display
        #Write-Output $pbarfull
        }
    Process {
        $i++
        write-verbose "Loading VM:($i/$numberOfVM)"
        write-debug "Loading VM: $_.guest"
        #LV
        #Write-Output '.'-NoNewline
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
        Write-Output "Got $numberOfVm VM's in $global:scrapespan"
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
        Write-Output 
        Write-Output $methodver
        foreach ($line in $outpage){
                if ($line.equals('')){continue} #catch and remove blanklines (generate real blanklines with a space)
                if ($line.contains('green')){ Write-Output $line -foregroundcolor green -backgroundcolor darkgreen}              
                elseif ($line.contains('yellow')){Write-Output $line -foregroundcolor yellow -backgroundcolor darkgray}
                elseif ($line.contains('red')){Write-Output $line -foregroundcolor yellow -backgroundcolor red}
                else {Write-Output $line -ForegroundColor darkgray -BackgroundColor blue}
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
    #Write-Output "firstrun: $firstrun"
    $columns = @{'property'='flag', 'pwrstate', 'guest', 'ip', 'rtt', 'flagreason', 'cpup', 'cpuhz','vmVer'}
    #take input vm's > grab data from them > sort by poperty > grab above columns | format in a table autosized and wrapped when needed > 
    $verbosepreference = 0
    $vms | scrape-vidata | sort cpup -Descending | select @columns | format-table -autosize | out-string | fromstring-colourize
    $refresh = 0
    $i = $refresh
    #Write-Output $methodver -nonewline
    while ($i -gt 0 ) {
        $i--
        Write-Output "." -NoNewline
        sleep -milliseconds 1000
        }
     
    }


Write-Output 'all functions loaded fresh'
Write-Output "Methods:$methodver"
