<#
Script:
    switch-witch.ps1
Author:
    Maximillian Schmidt (Github: @schmidtm)
    Oregon State University
    Information Services - Client Services - Service Desk
    maximillian.schmidt@oregonstate.edu
Version:
    v1.3.0
License:
    This software is covered by the GNU General Public License Version 3,
    29 June 2007. See https://www.gnu.org/licenses/gpl.txt for full
    license text.
Description:
    This script will structure the output for every check and everything
    returned from called scripts and variables. It will call the
    correct utilities to achieve this. It also has options for install-
    ing/uninstalling prerequisites.
Input:
    * WinDump's packet capture output
    * Yes or no prompt response for file output
Output:
    * A selected section of the broadcasted switch info
    * Optional file output of said result
Import:
    '#!#' denotes calling something not in this script, but from
    something imported. Please see the imported file for details.

    * pre_func_lib.ps1
      - Contains most operations to be done prior to the running
        of the main script. Also contains other operations.
    * wdts_func_lib.ps1
      - Contains helper functions to run WinDump and Tshark.
#>

#region Imports

#!# Import pre-script function library(contains flags and macros)

. "$PSScriptRoot\pre_func_lib.ps1"

#!# Import WinDump/Tshark function library

. "$PSScriptRoot\wdts_func_lib.ps1"

#endregion

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
########################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

### Pre-script and other operations ###
#region Pre-Script/Other

#!# > pre_func_lib.ps1

Check-Cmd-Line-Args($args)

# Output padding
Write-Host ""

Start-Transcript -Append -Path $LOG_FILE

Write-Host ""

Check-Dirs

#!#

#!# > wdts_func_lib.ps1

$Adapter = Get-Win-Adapter

Check-Requirements($Adapter.NetConnectionStatus)

$WD_ID = Match-GUIDs($Adapter.GUID)

#!#
#endregion

########################################################################################################################

### WinDump Job Start ###
#region WinDump Job

If (!$QUIET) {

    Write-Host "~~~ NOTE: LLDP announcements may take up to 90 seconds" -ForegroundColor Yellow
    Write-Host "Starting Windump...
    "
}

# Start separate job to call the script which runs WinDump
# Wait for this job to complete for 90 seconds
# Receive output and store in variable

$WDJob = Start-Job -ArgumentList @("$PSScriptRoot","$WD_ID","$HOST_NAME","$ERR_FILE") -FilePath "$PSScriptRoot\run-windump-for-lldp.ps1"

If ($VERBOSE) {

    Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
    Write-Host " Background job started.  Waiting for 90s..." -ForegroundColor Magenta
}

Wait-Job -Timeout 90 -Id $WDJob.Id

$PcapFile = Receive-Job $WDJob.Id

If ($VERBOSE) {

    Write-Host "
V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
    Write-Host " PcapFile: $Pcapfile
    " -ForegroundColor Magenta
}

#endregion

########################################################################################################################

### Based upon WinDump Job result: ###
Decide-Output($Pcapfile)

########################################################################################################################

### If Wireshark(test for tshark) has been installed, parse the packet ###

#region Tshark Parsing
$TSPath = 'C:\Program Files\Wireshark\tshark.exe'

If (Test-Path $TSPath) {

    Tshark-Parse -Path $TSPath -MAC $Adapter.MACAddress
}

# Tshark not installed...
Else {

    No-Tshark-Msg
}

#endregion

########################################################################################################################

### Finish up, final checks, end log output ###

#region Finish script

If (!$QUIET) {

    Write-Host "Finished!
" -ForegroundColor Green
}

# If the nocap switch
If (! $KEEPCAP) {

    If ($VERBOSE) {

        Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
        Write-Host " Removing current capture..." -ForegroundColor Magenta
    }

    Remove-Item .\cap-outputs\$HOST_NAME-windump.pcap -Force
}


Stop-Transcript


If (!$QUIET) {

    Write-Host "Log Updated..." -ForegroundColor Yellow
}

#endregion

exit

### END OF SCRIPT ###
