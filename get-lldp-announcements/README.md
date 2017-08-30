# Get Link Layer Discovery Protocol (LLDP) Info - Client-side

The purpose of these scripts is to provide a simple command line interface
to gather LLDP announcements on wired ethernet connections to a managed switch
that actively uses and supports the Link Layer Discovery Protocol.

***
## Devloper Info
### Maximillian Schmidt ( @cascadeth )
##### Oregon State University - ISCS - Service Desk
##### maximillian.schmidt(at)oregonstate.edu
Networking, Windows, Unix, Printers, and making stuff fit my needs in an
ever changing technological environment.  Find me on OSU-IT Slack: @schmidt.
Please IM or email me with thoughts, questions, or ideas!

***
### About
These scripts are currently designed to work with Oregon State University, Information
Services - Client Services - Service Desk, Community Network operations.
They have been developed for internal departmental use, and can be used in other
support departments or publicly as well.  If something doesn't quite fit or you
have feature requests, please feel free to email the developer.  Please see the wiki for
details on the scripts(work-in-progress).

### Licensing
The unix/Mac OS(X)(`sw.sh`, `prereqs.sh`) and Windows Powershell/batch scripts
(`pre_func_lib.ps1`, `run-windump-for-lldp.ps1`, `switch-witch.ps1`, `wdts_func_lib.ps1`,
 `run-me.bat`) are covered by the GNU GPL v3.  You are free to copy, redistribute,
 or change them as much as you like.  If you have suggested improvements, please send me an
email with your ideas!

The WinPcap and WinDump licenses are not GNU GLP v3.  They are assigned, copied
from the WinPcap organization website, and distributed with these scripts for their reference.

#### Note About Windows
Do NOT open the Unix based scripts in Windows and expect the same file to operate
on a unix based device.  The Windows new line carriage ending type will bork the
interpretation of the script.  
If you find that it still doesn't run, please run `dos2unix`* on the file.  If the
script still doesn't execute or run correctly, please feel free to email the developer.  


* `dos2unix` is conveniently installed via Homebrew in the prerequisite script
for Mac devices.  For Linux distributions, please see your distribution's
installation instructions for `dos2unix`.
