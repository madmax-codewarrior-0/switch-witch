#!/bin/bash
#################################################################################
#
# Script:
#   prereqs.sh
# Author:
#   Maximillian J Schmidt (Github: @cascadeth)
#   Oregon State University
#   Information Services - Client Services - Service Desk
#   maximillian.schmidt@oregonstate.edu
# Version:
#   v1.0.0
# License:
#   This software is covered by the GNU General Public License Version 3,
#   29 June 2007. See https://www.gnu.org/licenses/gpl.txt for full
#   license text.
# Description:
#   This script will determine what OS it is present in.  If Mac OS(X), it
#   will install Homebrew, GNU coreutils, and dos2unix.
# Input:
#   * N/A
# Output:
#   * Info regarding setup
#
#################################################################################


OS=$(uname)

if [ $OS != "Darwin" ]
then
	printf "OS is not Mac OS.\nNo setup required!\n\n"

	dos2unix sw.sh

	if [ -e ./VLANS.txt ]
	  dos2unix VLANS.txt
	fi

	exit 0
fi

printf "Installing homebrew...\n\n"

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"


printf "\n\n\nFinished\n\nInstalling coreutils..."

brew install coreutils


printf "\n\n\nFinished\n\nInstalling dos2unix..."

brew install dos2unix


# Run a quick conversion with dos2unix, just for good measure

dos2unix sw.sh

if [ -e ./VLANS.txt ]
  dos2unix VLANS.txt
fi

printf "\n\n\nFinished\n\n\nSetup Complete!\nYou may now run the main script with 'sudo ./sw.sh'\n\nExiting...\n\n"

exit 0
