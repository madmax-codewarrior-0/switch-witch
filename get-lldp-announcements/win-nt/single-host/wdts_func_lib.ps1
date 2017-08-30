<#
Library:
    wdts_func_lib.ps1
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
    This library holds functions necessary functions for running WinDump
    operations and tshark parsing.
Input: N/A
Output: N/A
#>



########################################################################################################################

### Get a device that matches the Ethernet description ###

function Get-Win-Adapter() {

    If (!$QUIET) {

        Write-Host "
Getting device GUID for WinDump...
    "
    }

    # Get the WMI object that matches the win32_networkadapter class,
    # where the name of each object in the class matches "Ethernet"
    # or "Local" or "Gigabit" or "GBE"(Giga Bit Ethernet) and the name
    # of each object does not match "Virtual" or "vEthernet"(Hyper-V's
    # name for ethernet) or "Hyper-V" or "VPN".
    $Interface = Get-WmiObject win32_networkadapter | Where {$_.Name -Match "Ethernet|Local|Gigabit|GBE" -and $_.Name -NotMatch "Virtual|vEthernet|Hyper-V|VPN|USB|Mobile"}

    If ($VERBOSE) {

        Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
        Write-Host " Wmi-Object GUID: " $Interface.GUID -ForegroundColor Magenta
    }

    # If no term found under this search
    # output message and quit
    If ($Interface -eq $null) {

        Write-Host "### No device found with search terms for Ethernet!" -ForegroundColor Red
        Write-Host "If you're sure you have a wired Ethernet device,
please email the developer so that it
can be added to the supported device names." -ForegroundColor Yellow

        Stop-Transcript

        Write-Host "Log Updated..." -ForegroundColor Magenta
        exit
    }

    # $DeviceName = Get-WmiObject win32_networkadapter | Where {$_.GUID -Match "$Interface"} | Select -ExpandProperty Name

    # $DeviceState = Get-WmiObject win32_networkadapter | Where {$_.GUID -Match "$Interface"} | Select -ExpandProperty NetConnectionStatus

    If ($VERBOSE) {

        switch ($Interface.NetConnectionStatus) {

            0  {$NetConnectionStatus_V = "Disconnected"}
            1  {$NetConnectionStatus_V = "Connecting"}
            2  {$NetConnectionStatus_V = "Connected"}
            3  {$NetConnectionStatus_V = "Disconnecting"}
            4  {$NetConnectionStatus_V = "Hardware Not Present"}
            5  {$NetConnectionStatus_V = "Hardware Disabled"}
            6  {$NetConnectionStatus_V = "Hardware Malfunction"}
            7  {$NetConnectionStatus_V = "Media Disconnected"}
            8  {$NetConnectionStatus_V = "Authenticating"}
            9  {$NetConnectionStatus_V = "Authentication Succeeded"}
            10 {$NetConnectionStatus_V = "Authentication Failed"}
            11 {$NetConnectionStatus_V = "Invalid Address"}
            12 {$NetConnectionStatus_V = "Credentials Required"}
        }

        Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
        Write-Host " NetConnectionStatus: $NetConnectionStatus_V ("$Interface.NetConnectionStatus")
        " -ForegroundColor Magenta
    }

    $D_Name = $Interface.Name
    $D_GUID = $Interface.GUID

    If (!$QUIET) {

        Write-Color -Text "Found Windows device:  ","$D_Name --- \Device\NPF_$D_GUID" -Color White,Green
    }

    return $Interface
}



########################################################################################################################

### Check prior requirements for LLDP announcements capture ###

function Check-Requirements([String]$status) {

    # Not really necessary, but it is the actual driver file
    If (!(Test-Path 'C:\Windows\System32\drivers\npf.sys')) {

        Write-Host "
### WinPcap driver not installed!
        " -ForegroundColor Red
        Write-Host "Please run '.\switch-witch.ps1 -i'
        " -ForegroundColor Yellow

        Stop-Transcript

        Write-Host "Log Updated..." -ForegroundColor Magenta
        exit
    }


    # If the device has not established a link
    If ($status -ne 2) {

        Write-Host "### Ethernet Not Connected!
        " -ForegroundColor Red
        Write-Host "Please check your cable and ports!
        " -ForegroundColor Yellow

        Stop-Transcript

        Write-Host "Log Updated..." -ForegroundColor Magenta
        exit
    }

    If ($VERBOSE) {

        Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
        Write-Host " Requirements met - continuing..." -ForegroundColor Magenta
    }
}



########################################################################################################################

### Run `WinDump -D` and match GUID to output ###

function Match-GUIDs([String]$GUID) {

    # Run WinDump's "list devices" command and select
    # the string/line that has the correct GUID.
    # Convert the object to a string, then a char array
    # The first char in the array will be the interface
    # ID to be used with WinDump

    $WDAdapter = Invoke-Command {.\WinDump.exe -D | Select-String $GUID}

    If ($WDAdapter -eq $null) {

        Write-Host "
### WinPcap driver not installed!
        " -ForegroundColor Red
        Write-Host "Please run '.\switch-witch.ps1 -i'
        " -ForegroundColor Yellow

        Stop-Transcript

        Write-Host "Log Updated..." -ForegroundColor Magenta
        exit
    }

    $WDAdapter_S = $WDAdapter.ToString()
    $WDAdapter_CA = $WDAdapter_S.toCharArray()

    $WDInterface = $WDAdapter_CA[0]

    If (!$QUIET) {

        Write-Color -Text "Found WinDump's ID:    ","$WDInterface`n" -Color White,Green
    }

    return $WDInterface
}



########################################################################################################################

### Based upon the output of the Job, ###
### decide what to do...              ###

function Decide-Output([String]$PcapPath) {

    # If the job returns 1, then WinDump couldn't run
    If ($PcapPath -eq 1) {

        Write-Host "
    $FAIL_MSG
        " -ForegroundColor Red

        Write-Host "WinDump was unable to run.
Check If the WinPcap driver is installed and running!
    " -ForegroundColor Yellow

        Remove-Item .\log\*.tmp

        If ($VERBOSE) {

            Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
            Write-Host " Removed stderr.tmp..." -ForegroundColor Magenta
        }

        Stop-Transcript

        Write-Host "Log Updated..." -ForegroundColor Magenta
        exit
    }

    # If the error file still exists, the job timed out
    # and no announcement was detected
    ElseIf (Test-Path $ERR_FILE) {

        Write-Host "
$FAIL_MSG
        " -ForegroundColor Red

        Write-Host "No announcement detected.
Check your connection!
        " -ForegroundColor Yellow

        # Need to kill the WinDump process to get rid of
        # of the temporary stderr output file
        If ($VERBOSE) {

            Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
            Write-Host " Killing WinDump process...
            " -ForegroundColor Magenta
        }

        Stop-Process -Name WinDump -Force

        If ($VERBOSE) {

            Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
            Write-Host " Waiting for process to end...
            " -ForegroundColor Magenta
        }

        # Wait for process to stop
        Start-Sleep -Seconds 5

        # Then remove item, since
        Remove-Item .\log\*.tmp

        If ($VERBOSE) {

            Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
            Write-Host " Removed stderr.tmp...
            " -ForegroundColor Magenta
        }

        Stop-Transcript

        Write-Host "Log Updated..." -ForegroundColor Magenta

        exit
    }

    # Else everything completed correctly
    Else {

        If ($VERBOSE) {

            Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
            Write-Host " Starting tshark for packet fields..." -ForegroundColor Magenta
        }

        Write-Host "

$SUCC_MSG" -ForegroundColor Cyan
    }

}



########################################################################################################################

### Use Tshark to parse the packet capture ###
### Look for VLAN file and output result   ###
### Ask to save if write switch not active ###

function Tshark-Parse([String]$Path, [String]$MAC) {

    If (!$QUIET) {

        Write-Host "Parsing dump..."
    }

    # Tshark can give us each field in the pcap dump
    $SW_SYST_NAME = & $Path -T fields -e lldp.tlv.system.name -r $PcapFile
    $SW_IP_ADDRES = & $Path -T fields -e lldp.mgn.addr.ip4 -r $PcapFile
    $SW_SHRT_PORT = & $Path -T fields -e lldp.port.id -r $PcapFile
    $SW_LONG_PORT = & $Path -T fields -e lldp.port.desc -r $PcapFile
    $SW_P_VLAN_ID = & $Path -T fields -e lldp.ieee.802_1.port_vlan.id -r $PcapFile


    # Check the VLAN ID for matching known VLAN IDs
    # Open the VLANS file and read each line
    # If the first string before '=' is equal to the
    #  found announced VLAN ID, take the string after
    #  the '=' to be the VLAN name
    If (Test-Path $VLANS) {

        $V_FILE = Get-Content $VLANS

        foreach ($line in $V_FILE) {

            $VID,$VNAME = $line.split('=')

            If ($VID -eq $SW_P_VLAN_ID) {

                $VLAN_NAME = $VNAME
            }

        }
    }

    # No VLAN file found
    Else {

        Write-Host "No VLANS file found!" -ForegroundColor Yellow
        Write-Host "Please produce a VLANS file for ID matching..." -ForegroundColor Yellow
        $VLAN_NAME = "Unknown"
    }

    # Format everything out pretty
    If (!$QUIET) {

        # If the VLAN switch
        If ($VLAN_ONLY) {

            Write-Host "
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" -ForegroundColor DarkCyan

            Write-Color -Text "   Port VLAN ID: ","$SW_P_VLAN_ID ( $VLAN_NAME )`n" -Color Yellow,Green

            Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor DarkCyan
        }

        # Normal output
        Else {

            $Output = Write-Color -Text "
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`n" -Color DarkCyan

            $Output += Write-Color -Text "   Switch Name:     ","$SW_SYST_NAME`n" -Color Yellow,Green

            $Output += Write-Color -Text "   Switch IP Addr:  ","$SW_IP_ADDRES`n" -Color Yellow,Green

            $Output += Write-Color -Text "   Switch Port:     ","$SW_SHRT_PORT ( $SW_LONG_PORT )`n" -Color Yellow,Green

            $Output += Write-Color -Text "   Port VLAN ID:    ","$SW_P_VLAN_ID ( $VLAN_NAME )`n" -Color Yellow,Green

            $Output += Write-Color -Text "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -Color DarkCyan

            Write-Host $Output
        }
    }

    # If the write switch
    If ($WRITE) {

        Write-Output "Host: $HOST_NAME" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE"
        Write-Output "Date: $DATE" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append
        Write-Output "MAC:  $MAC" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

        Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

        Write-Output "   Switch Name:     $SW_SYST_NAME
        " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

        Write-Output "   Switch IP Addr:  $SW_IP_ADDRES
        " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

        Write-Output "   Switch Port:     $SW_SHRT_PORT ( $SW_LONG_PORT )
        " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

        Write-Output "   Port VLAN ID:    $SW_P_VLAN_ID ( $VLAN_NAME )
        " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

        Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`n" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

        If (!$QUIET) {

            Write-Host "Saved to $WR_OUTPUT_PATH\$WR_OUTPUT_FILE"
        }
    }

    # Ask if they want to save anyway...
    Else {

        $SAVE = Read-Host -Prompt 'Would you like to save this output? (y/n) '
        Write-Host ""

        If ($SAVE -match "Y|y") {

            Write-Output "Host:  $HOST_NAME" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE"
            Write-Output "Date:  $DATE" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append
            Write-Output "MAC:   $MAC" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

            Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

            Write-Output "   Switch Name:     $SW_SYST_NAME
            " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

            Write-Output "   Switch IP Addr:  $SW_IP_ADDRES
            " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

            Write-Output "   Switch Port:     $SW_SHRT_PORT ( $SW_LONG_PORT )
            " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

            Write-Output "   Port VLAN ID:    $SW_P_VLAN_ID ( $VLAN_NAME )
            " | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

            Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`n" | Out-File "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE" -Append

            Write-Host "Saved to "$WR_OUTPUT_PATH\$WR_OUTPUT_FILE"
            "
        }
    }

}



########################################################################################################################

### If tshark not installed on system ###

function No-Tshark-Msg() {

    If ($VERBOSE) {

        Write-Host "V" -ForegroundColor Black -BackgroundColor Magenta -NoNewline
        Write-Host " Tshark not installed to parse packet..." -ForegroundColor Magenta
    }

    If (!$QUIET) {

        Write-Host "
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" -ForegroundColor DarkCyan

        Write-Host "Use Wireshark to further analyze the packet." -ForegroundColor Yellow
        Write-Host "Tshark is recommended for command line parsing.
" -ForegroundColor Yellow

        Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" -ForegroundColor DarkCyan

    }
}



### END OF FUNCTION LIST ###
