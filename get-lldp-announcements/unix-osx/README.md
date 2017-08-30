# Switch-Witch

## Prerequisites

### Mac OS(X)

  * For Mac OS(X) please run the prerequisites script(`prereqs.sh`) if you do not have the following packages installed:

    * Homebrew (https://brew.sh/) and its packages for Mac OS(x)
      * `coreutils` - GNU Core Utilities; more command/binaries for simplicity
      * `dos2unix` - Convert Windows/DOS new line carriages over to no carriages


## Install

  * No installation necessary, unless you have NOT completed the prerequisites for Mac OS(X). Just run.

***

## File Info

  * `change_log.txt` --- Self-explanatory...

  * `sw.sh` --- The main script housing the file I/O and other system calls

  * `prereqs.sh` --- A package installer script for Mac OS(X) (homebrew, coreutils, dos2unix)

***

## Run

Run from the terminal/console: `sudo ./sw.sh [options]` (or however you need to elevate to root to run tcpdump)  

***

## Custom Additions

  * VLAN Naming
    * `VLANS.txt` is put in the main script directory (`<your_dir>\win-nit\single-host\VLANS.txt`)
    * Allows specified VLAN IDs to be named and recalled in the script.  Example output: `Port VLAN ID:    1234 (SOOPER_BEST_W)`
    * File Contents Format: `<NUM>=<NAME>`
      ```python
      1234=SOOPER_BEST_W
      5678=ALMOST_SOOPER
      9101=NORMAL_BEST_W
      6666=VIRUS_GO_HERE
      9999-HOW_U_GET_OUT
      ```
