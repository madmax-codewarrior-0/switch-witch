<#
Library:
    pre_func_lib.ps1
Author:
    Maximillian Schmidt (Github: @schmidtm)
    Oregon State University
    Information Services - Client Services - Service Desk
    maximillian.schmidt@oregonstate.edu
Version:
    v1.0
License:
    This software is covered by the GNU General Public License Version 3,
    29 June 2007. See https://www.gnu.org/licenses/gpl.txt for full
    license text.
Description:
    This library holds functions necessary functions for pre-script
    operations and other functions.
Input: N/A
Output: N/A
#>

### Define Macros ###

$global:HOST_NAME = & hostname
$global:DATE = Get-Date -f yyyy-MM-dd
$global:LOG_FILE = "$PSScriptRoot\log\$HOST_NAME--$DATE--log.txt"
$global:ERR_FILE = "$PSScriptRoot\log\stderr.tmp"
$global:WR_OUTPUT_PATH = "C:$env:HOMEPATH"
$global:WR_OUTPUT_FILE = "$HOST_NAME--$DATE--sw-output.txt"
$VLANS = "$PSScriptRoot\VLANS.txt"

$SUCC_MSG = "=== Packet capture: SUCCESSFUL"
$FAIL_MSG = "### Packet capture: UNSUCCESSFUL"

# Flags
$global:KEEPCAP = $False
$global:QUIET = $False
$global:VERBOSE = $False
$global:VLAN_ONLY = $False



########################################################################################################################

### Color output helper function ###

function Write-Color ([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0,[int] $LinesAfter = 0) {

    $DefaultColor = $Color[0]

    # Add empty line before
    If ($LinesBefore -ne 0) {

        for ($i = 0; $i -lt $LinesBefore; $i++) {

            Write-Host "`n" -NoNewline
        }
    }

    # Add TABS before text
    If ($StartTab -ne 0) {

        for ($i = 0; $i -lt $StartTab; $i++) {

            Write-Host "`t" -NoNewLine
        }
    }

    If ($Color.Count -ge $Text.Count) {

        for ($i = 0; $i -lt $Text.Length; $i++) {

            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine
        }
    }

    Else {

        for ($i = 0; $i -lt $Color.Length ; $i++) {

            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine
        }

        for ($i = $Color.Length; $i -lt $Text.Length; $i++) {

            Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine
        }
    }

    # Add empty line after
    Write-Host
    If ($LinesAfter -ne 0) {

        for ($i = 0; $i -lt $LinesAfter; $i++) {

            Write-Host "`n"
        }
    }

}



########################################################################################################################

### Show help ###

function Show-Help () {

    Write-Host "
  ~~~ Switch-Witch Help ~~~
    " -ForegroundColor Magenta
    Write-Host "  Usage:  .\switch-witch.ps1 [Options]
    " -ForegroundColor Cyan
    Write-Host "  Options:" -ForegroundColor Yellow
    Write-Host "            -c,  --clean      :  Start fresh; clean up everything, like it never happened... "
    Write-Host "            -h,  --help       :  It's how you got here! :D"
    Write-Host "            -i,  --install    :  Quick launch a download and launch of the WinPcap driver installer"
    Write-Host "            -k,  --keep       :  Keep capture; default is to remove the pcap file;" -NoNewline
    Write-Host " if kept user should know security implications!" -ForegroundColor Yellow
    Write-Host "            -q,  --quiet      :  Quiet or minimal output; shows background job completion and success/failure"
    Write-Host "            -u,  --uninstall  :  Quick launch for the Pcap driver uninstaller;" -NoNewline
    Write-Host " NOTE: This also performs clean!" -ForegroundColor Yellow
    Write-Host "            -v,  --verbose    :  Verbose output; showing more actions taken"
    Write-Host "  *Planned* -vv, --vverbose   :  Very verbose; show even more actions taken"
    Write-Host "            -V,  --VLAN       :  Only output the currently assigned VLAN"
    Write-Host "            -w,  --write [opt]:  Write to file; saves to user folder by default"
    Write-Host "                                   If next arg isn't a switch, it will be used as the write path(no dashes in path currently)
    " -ForegroundColor Yellow
}



########################################################################################################################

### Clean up everything ###

function Clean-Up () {

    Write-Host "
~~~ This will remove all logs, captures, and capture outputs in the default locations!" -ForegroundColor Yellow
    Write-Host "    Are you sure? (y/n) " -ForegroundColor Red -NoNewline
    $Check = Read-Host

    If ($Check -match "Y|y") {

        If (Test-Path "$PSScriptRoot\cap-outputs") {
            Remove-Item "$PSScriptRoot\cap-outputs" -Force -Recurse
            Write-Host "Removed..." -ForegroundColor Magenta
        }
        If (Test-Path "$PSScriptRoot\log") {
            Remove-Item "$PSScriptRoot\log" -Force -Recurse
            Write-Host "Removed..." -ForegroundColor Magenta
        }
        If (Test-Path "C:$env:HOMEPATH\Desktop\*-sw_output.txt") {
            Remove-Item "C:$env:HOMEPATH\Desktop\*-sw_output.txt" -Force -Recurse
            Write-Host "Removed..." -ForegroundColor Magenta
        }
    }

    Else {

        Write-Host "
Then why are we here?..." -ForegroundColor Yellow
    }
}



########################################################################################################################

### Get pcap driver installer ###

function Get-Driver() {

    If (Test-Path 'C:\Program Files (x86)\WinPcap\Uninstall.exe') {

        Write-Host "Driver already installed!" -ForegroundColor Yellow
    }

    Else {
        Write-Host "Downloading driver and install helper..." -ForegroundColor Yellow

        If (!(Test-Path "$PSScriptRoot\driver\")) {

            New-Item $PSScriptRoot\driver\ -type Directory | Out-Null
        }

        Invoke-WebRequest -Uri https://www.winpcap.org/install/bin/WinPcap_4_1_3.exe -OutFile "$PSScriptRoot\driver\WinPcap_4_1_3.exe"
        Invoke-WebRequest -Uri http://sync.patchquest.com/dccrs/updates/winpcapsilent.exe -OutFile "$PSScriptRoot\driver\WinPcap_Silent.exe"

        Write-Host "Installing driver..." -ForegroundColor Yellow
        & "$PSScriptRoot\driver\WinPcap_Silent.exe" "$PSScriptRoot\driver\WinPcap_4_1_3.exe"

        # Wait for install to finish
        Start-Sleep -Seconds 6

        Write-Host "Driver installed... Welcome to the cool kids club!" -ForegroundColor Magenta

        If (Test-Path "$PSScriptRoot\driver\") {

            Remove-Item "$PSScriptRoot\driver" -Force -Recurse
            Write-Host "Removed installer..." -ForegroundColor Yellow
        }
    }
}



########################################################################################################################

### Complete uninstall of driver ###

function Invoke-Uninstall() {

    If (Test-Path 'C:\Program Files (x86)\WinPcap\Uninstall.exe') {

        Write-Host "
~~~ This will launch the Pcap driver uninstaller!" -ForegroundColor Yellow
        Write-Host "    Are you sure? (y/n) " -ForegroundColor Red -NoNewline
        $Check = Read-Host

        If ($Check -match "Y|y") {

            & 'C:\Program Files (x86)\WinPcap\Uninstall.exe'
            Write-Host "Finished..." -ForegroundColor Magenta
        }

        Else {

            Write-Host "
Then why are we here?..." -ForegroundColor Yellow
        }
    }

    Else {

            Write-Host "
No uninstaller found!" -ForegroundColor Red
            Write-Host "Please be sure the driver is already installed..." -ForegroundColor Yellow
    }

    Clean-Up
}



########################################################################################################################

### Check for required subdirectory ###

# Apparently WinDump can't create subdirectories when writing to a file
function Check-Dirs() {

    If ( !(Test-Path $PSScriptRoot\cap-outputs\) ) {

        New-Item $PSScriptRoot\cap-outputs\ -type Directory | Out-Null

        If ($VERBOSE) {

            Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
            Write-Host " No cap-output subdirectory found.    Created it..." -ForegroundColor Magenta
        }
    }
}



########################################################################################################################

### Check command line options ###

function Check-Cmd-Line-Args([string[]]$cmd_args) {

    for ($i = 0; $i -lt $cmd_args.length; $i++) {

        # start fresh, no pcaps, logs, outputs
        If ($cmd_args[$i] -cmatch "-c|--clean") {

            Clean-Up
            exit
        }

        # show help
        If ($cmd_args[$i] -cmatch "-h|--help") {

            Show-Help
            exit
        }

        # get the driver installers and install
        If ($cmd_args[$i] -cmatch "-i|--install") {

            Get-Driver
            exit
        }

        # no capture left after script
        If ($cmd_args[$i] -cmatch "-k|--keep") {

            $global:KEEPCAP = $True
        }

        # quiet or little output
        If ($cmd_args[$i] -cmatch "-q|--quiet") {

            $global:QUIET = $True
        }

        # clean and uninstall pcap driver
        If ($cmd_args[$i] -cmatch "-u|--uninstall") {

            Invoke-Uninstall
            exit
        }

        # verbose type output
        If ($cmd_args[$i] -cmatch "-v|--verbose") {

            $global:VERBOSE = $True
            Write-Host "                                     " -BackgroundColor Magenta
            Write-Host "   FOUND VERBOSE SWITCH - SET FLAG   " -ForegroundColor Magenta
            Write-Host "                                     " -BackgroundColor Magenta

        }

        # VLAN only output
        If ($cmd_args[$i] -cmatch "-V|--VLAN") {

            $global:VLAN_ONLY = $True
        }

        # Write to file, default is user desktop
        If ($cmd_args[$i] -cmatch "-w|--write") {

            $global:WRITE = $True
            if ($cmd_args[$i + 1] -cnotmatch "-|--") {

                $global:WR_OUTPUT_PATH = $cmd_args[$i + 1]
            }
        }
    }
}



### END OF FUNCTION LIST ###
