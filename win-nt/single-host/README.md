# Single-Host

## Prerequisites

### Software

  * Powershell     --- You should already have it

  * WinPcap Driver --- You will need to get this if you haven't already.  You can find it [here](https://www.winpcap.org/install/default.htm) or run `.\switch-witch -i`

  * Wireshark      --- Used to parse the dumped packet.  You can find it [here](https://www.wireshark.org/#download)
     * Technically optional, but really does the information handling.

### Install

  * Open an elevated Powershell(Run as Administrator).  Also make sure you have script execution rights on your device.  Navigate to the directory of the main script `switch-witch.ps1` and run: `.\switch-witch.ps1 -i`  This will download the WinPcap driver from the WinPcap organization's site and a simple compiled executable to run the WinPcap driver installer for you.  This launcher executes the driver installer and just presses Return/Enter for you).  
    * This method will be phased out when a WinPcap driver silent installer is developed.  

***

## File Info

  * `change_log.txt` --- Self-explanatory...

  * `pre_func_lib.ps1` --- A imported file to the main script; contains pre operations and other functions

  * `run-me.bat` --- A batch file for simple running
  * `run-windump-for-lldp.ps1` --- A subscript called as a background job; runs WinDump with filters for LLDP

  * `switch-witch.ps1` --- The main script; handles function calling and minimal work

  * `wdts_func_lib.ps1` --- An imported file to the main script; contains functions essential to main objective

  * `WinDump.exe` --- Executable to look for packets on a network interface; requires WinPcap driver; takes lots of options

***

## Run

Simply run `run-me.bat`, which will execute the Powershell scripts normally(no packet capture left behind).
Please run the script in a Powershell console for extra options and functionality.
Use option `-h` with `switch-witch.ps1` in Powershell for help.

***

## Custom Additions

  * VLAN Naming
    * `VLANS.txt` is put in the main script directory (`<your_dir>\win-nt\single-host\VLANS.txt`)
    * Allows specified VLAN IDs to be named and recalled in the script.  Example output: `Port VLAN ID:    1234 (SOOPER_BEST_W)`
    * File Contents Format: `<NUM>=<NAME>`
      ```python
      1234=SOOPER_BEST_W
      5678=ALMOST_SOOPER
      9101=NORMAL_BEST_W
      6666=VIRUS_GO_HERE
      9999-HOW_U_GET_OUT
      ```
