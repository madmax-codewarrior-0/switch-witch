<#
Script:
    run-windump-for-lldp.ps1
Author:
    Maximillian Schmidt (Github: @schmidtm)
    Oregon State University
    Information Services - Client Services - Service Desk
    maximillian.schmidt@oregonstate.edu
Version:
    v1.2
License:
    This software is covered by the GNU General Public License Version 3,
    29 June 2007. See https://www.gnu.org/licenses/gpl.txt for full
    license text.
Description:
    This script will pull Link Layer Discovery Protocol (LLDP)
    announcement packets off the local device's physical ethernet
    adapter, if the switch supports the protocol. This is a raw packet
    dump to a file, and removal of Powershell's error handling of
    curly braces ' {this_jargen_is_still_good} '
Input:
    * Parameters to WinDump's ouput
Output:
    * Stderr to a file, that is removed
    * Raw packet dump binary pcap file
#>

# WinDump with options for LLDP and file outputs

$WorkinDir = $args[0]
$InterfaceID = $args[1]
$Name = $args[2]
$ErrorDump = $args[3]

$ErrFlag = 1

$Command = "$WorkinDir\WinDump.exe"

$PcapFile = "$WorkinDir\cap-outputs\$Name-windump.pcap"
$MTUSize = "1522"
$Filter = "(ether proto 0x88cc)"

<#

@ Options:
    -w           : write to file, .pcap specifically
    $PcapFile    : Our file name
    -i           : use this specific interface
    $InterfaceID : Should be resolved to the Ethernet over wire NIC in main script
    -nn          : don't convert addresses to names heavily
    -vvv         : even more verbose output
    -s           : Specify MTU size for static frame size
    -c           : capture this many packets
    1            : 1 packet only
    $Filter
        ether    : use an ethernet frame
        proto    : matching the protocol
        0x88cc   : the Link Layer Discovery Protocol LLC header type

#>
$Options = @("-w", "$PcapFile", '-i', "$InterfaceID", "-nn", "-vvv", "-s", "$MTUSize", "-c", "1", "$Filter")

# Powershell doesn't like Windump's curly braces around the device GUID,
# so we have to dump stderr to a file and remove it. It still
# shows up in the log file however.
& $Command $Options 2> $ErrorDump

# If WinDump exits incorrectly, return a error flag
if (!($LASTEXITCODE -eq 0)) {

    return $ErrFlag
}

# So if it's not relevant, delete it
Remove-Item $ErrorDump

$PcapFile
