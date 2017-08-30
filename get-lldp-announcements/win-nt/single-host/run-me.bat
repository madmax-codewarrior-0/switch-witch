::#################################################################################
::
:: Script:
::   run-me.bat
:: Author:
::   Maximillian J Schmidt (Github: @cascadeth)
::   Oregon State University
::   Information Services - Client Services - Service Desk
::   maximillian.schmidt@oregonstate.edu
:: Version:
::   v1.0
:: License:
::   This software is covered by the GNU General Public License Version 3,
::   29 June 2007. See https://www.gnu.org/licenses/gpl.txt for full
::   license text.
:: Description:
::   This script will simply run the main Powershell script (switch-witch.ps1)
::   with the default options, bypassing execution policy for this instance.
:: Input:
::   * N/A
:: Output:
::   * A selected section of the broadcasted switch info
::   * An optional file output of said result
::
::#################################################################################

:: Simply run the main script, bypassing execution policy on machine
:: Default leaves no pcap file
powershell -executionpolicy Bypass -file "%~dp0switch-witch.ps1" -q

:: Pause to show results of Ps script
pause

:: Run the cleanup options
powershell -executionpolicy Bypass -file "%~dp0switch-witch.ps1" -c

