#!/bin/bash

#################################################################################
#
# Script:
#   sw.sh
# Author:
#   Maximillian J Schmidt (Github: @cascadeth)
#   Oregon State University
#   Information Services - Client Services - Service Desk
#   maximillian.schmidt@oregonstate.edu
# Version:
#   v1.3.0
# License:
#   This software is covered by the GNU General Public License Version 3,
#   29 June 2007. See https://www.gnu.org/licenses/gpl.txt for full
#   license text.
# Description:
#   This script will pull Link Layer Discovery Protocol (LLDP)
#   announcement packets off the local device's physical ethernet
#   adapter, if the switch supports the protocol. This includes the switch
#   FQDN, IP Address, the Switch Port Interface the client is connected to,
#   and the VLAN ID the Port is assigned.
# Input:
#   * The built in application tcpdump plus filter for LLDP packets
# 	  * Yes or no prompts for file output
# Output:
#   * A selected section of the broadcasted switch info
#   * An optional file output of said result
#
# Exit Codes:
#		* 0 - normal exit; no errors
#   * 1 - command error; permission level
#   * 2 - tcpdump timeout; no announcement
#
#################################################################################

### Start Macro Declarations ###

SHRT_HOST=$(hostname -s)
LONG_HOST=$(hostname -f)
DATE=$(date)
TIMEOUT="90s"
OS_NAME=$(uname)
USER=$(whoami)

# Network adapter number to listen on
#   On-board ethernet will most always be '1.en0 [Up, Running]'(Mac OS) or '1.eth0'(Linux)
#   External adapters will be something like '9.en5 [Up, Running]'
ADAPTER=1


# Default file outputs
PACK_DUMP="$SHRT_HOST"-lldp-dump.pcap
PACK_TEMP_DEST="$HOME/"
PACK_END_DEST="$HOME/Desktop/"

RSLT_FILE="$SHRT_HOST"-result.txt
RSLT_TEMP_DEST="$HOME/"
RSLT_END_DEST="$HOME/Desktop/"

# Command flops
DIRECT_OR_RAW="DIRECT"

# Flags for program behavior
KEEP_CAP=0
VERBOSE=0
WRT_FLAG=0


### End Macro Delarations ###

#################################################################################

### FUNC: Show Help ###

help() {

	printf "\n"
	printf "Usage: sudo ./sw.sh [options]\n\n"

	printf "Options: \n"
	printf "  -h | --help | -?              : Show this help message\n"
	printf "  -i | --interface [NUM]        : Select the interface to listen on;\n"
	printf "                                  NUM is the interface listed in\n"
	printf "                                  running 'tcpdump -D'\n"
	printf "  -k | --keep                   : Keep the packet capture output if it\n"
	printf "                                  needs to be transferred elsewhere\n"
	printf "                                  Using option '--raw' will do this by\n"
	printf "                                  default. \n"
	printf "  -o [path] | --outpath [path]  : Write output to the path given;\n"
	printf "                                  Do not use file name, just path.\n"
	printf "                                  We've got the file name taken care\n"
	printf "                                  of.\n"
	printf "  -r | --raw                    : Dump a raw binary-type packet for\n"
	printf "                                  future analysis elsewhere(Wireshark)\n"
	printf "  -v | --verbose                : Print actions/details\n"
	printf "\n"

}

### END FUNC ###

#################################################################################

### START CMD Line Options ###

# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
#
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).

# case structure:
#   -short|--long_opt)   :  the option
#     do stuff           :  change your script behavior, set flags, etc
#     shift              :  shift past if next argument is a value for the option
#		;;                   :  end the case statement

while [[ $# -gt 0 ]]
do

  key="$1"

  case $key in

		"--default")
			# LOL do nothin'
		;;

		"-i"|"--interface")
			ADAPTER=$2
			shift # past argument
		;;

		"-h"|"--help"|"-?")
			help
			exit 0
		;;

		"-k"|"--keep")
      KEEP_CAP=1
      # no shift
    ;;

		"-o"|"--outpath")
			WRT_FLAG=1
			RSLT_END_DEST="$2"
			shift # past argument
		;;

		"-r"|"--raw")
			DIRECT_OR_RAW="RAW"
		;;

		"-v"|"--verbose")
			VERBOSE=1
			printf "\n  *!* VERBOSE FLAG SET *!*\n\n"
			# no shift
		;;

    *)
      # unknown option, do nothin'
    ;;

  esac # end of cases

  shift # past argument or value
done

if [ $VERBOSE == 1 ]
then

	printf "KEEP CAPTURE FLAG              = $KEEP_CAP\n"
	printf "WRITE FLAG                     = $WRT_FLAG\n"
	printf "WRITE PATH                     = $RSLT_END_DEST\n"
	printf "DIRECT OUTPUT OR WRITE BINARY  = $DIRECT_OR_RAW\n"
	printf "SELECTED ADAPTER FOR TCPDUMP   = $ADAPTER\n\n"
	tcpdump -D
	printf "\n\n"
fi

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
		exit 1
fi

### END CMD Line Options ###


### Start Main Script Funtions ###

#######################################################################
# Start tcpdump, send results to temp file, parse through the dump for
# the switch name, the switch's IP address, the switch port interface,
# and the VLAN ID.  Cut each to a variable.
#######################################################################

printf "Launching tcpdump... \n"
printf "LLDP announcements may take up to $TIMEOUT\n\n"

printf "You need administrator rights to run tcpdump\n"
printf "Please enter your credentials if prompted\n\n"

# Run tcpdump on with a timeout, waiting for a LLDP announcement from the switch
# Direct it's output into a packet capture(.pcap) file
# Grab the file stats to see if a dump packet was captured; store in variable

# tcpdump command and arguments:
	# -i $ADAPTER         :  interface number X;
	# -nn                 :  don't convert addresses to names heavily
	# -vvv                :  the most verbose output
	# -s 1522             :  MTU size is 1522 bytes
	# -c 1                :  capture count is 1 packet only
	# ether proto 0x88cc  :  Filter incoming packets by the ethernet header protocol 0x88cc
	#                        (the LLDP protocol)



if [ $OS_NAME == "Linux" ]
then

	if [ $DIRECT_OR_RAW == "DIRECT" ]
	then

		sudo timeout -s HUP $TIMEOUT tcpdump -i $ADAPTER -nn -vvv -s 1522 -c 1 ether proto 0x88cc > "$PACK_TEMP_DEST""$PACK_DUMP"
		SIZE=$(stat -c %s "$PACK_TEMP_DEST""$PACK_DUMP" | tr "\n" ": " | cut -d ":" -f 1)

	elif [ $DIRECT_OR_RAW == "RAW" ]
	then

		sudo timeout -s HUP $TIMEOUT tcpdump -i $ADAPTER -nn -vvv -s 1522 -c 1 ether proto 0x88cc -w "$PACK_END_DEST""$PACK_DUMP"
		SIZE=$(stat -c %s "$PACK_END_DEST""$PACK_DUMP" | tr "\n" ": " | cut -d ":" -f 1)

	fi

elif [ $OS_NAME == "Darwin" ]
then

	if [ $DIRECT_OR_RAW == "DIRECT" ]
	then

		sudo gtimeout -s HUP $TIMEOUT tcpdump -i $ADAPTER -nn -vvv -s 1522 -c 1 ether proto 0x88cc > "$PACK_TEMP_DEST""$PACK_DUMP"
		SIZE=$(gstat -c %s "$PACK_TEMP_DEST""$PACK_DUMP" | tr "\n" ": " | cut -d ":" -f 1)

	elif [ $DIRECT_OR_RAW == "RAW" ]
	then

		sudo gtimeout -s HUP $TIMEOUT tcpdump -i $ADAPTER -nn -vvv -s 1522 -c 1 ether proto 0x88cc -w "$PACK_END_DEST""$PACK_DUMP"
		SIZE=$(gstat -c %s "$PACK_END_DEST""$PACK_DUMP" | tr "\n" ": " | cut -d ":" -f 1)

	fi

else

	printf "OS not recognized! timeout or gtimeout not useable...\nExiting...\n\n"
	exit 1
fi


if [ $VERBOSE == 1 ]
then

	printf "Written packet output size: $SIZE\n"

fi

# If raw binary packet type, we can't parse it
# without another program currently; just exit
if [ $DIRECT_OR_RAW == "RAW" ]
then

	exit 0
fi

# If packet capture(file is size is greater than 1),
# parse through the capture and find each field
# Else print message saying nothing found
if [[ "$SIZE" -gt 1 ]]
then

	# Find the following fields in the packet and pull their values to a variable
	SW_NAME=$(grep "System Name" "$PACK_TEMP_DEST""$PACK_DUMP" | cut -d ":" -f 2)

	SW_IP_ADDR=$(grep "Management Address length 5" "$PACK_TEMP_DEST""$PACK_DUMP" | cut -d ":" -f 2)

	SW_PORT=$(grep "Port Description" "$PACK_TEMP_DEST""$PACK_DUMP" | cut -d ":" -f 2)

	SW_PORT_SHRT=$(grep "Subtype Interface Name" "$PACK_TEMP_DEST""$PACK_DUMP" | cut -d ":" -f 2)

	VLAN_ID=$(grep "port vlan id" "$PACK_TEMP_DEST""$PACK_DUMP" | cut -d ":" -f 2)


	# If a VLAN ID to VLAN name file is present
	if [ -f VLANS.txt ]
	then

		# Read the file line by line
		# Split the line by the '=' sign and store in two different column variables
	  while IFS='=' read -r ID_col NAME_col
	  do

			# If the VLAN ID pulled from the packet dump matches
			# the ID on the current line of the file
	  	if [ $VLAN_ID = $ID_col ]
	    then

				# Assign the VLAN name on the line
				# to a variable and break the loop
				VLAN_NAME=$NAME_col
				break
			else

				# The VLAN ID is not matched to a
				# VLAN name in the VLAN.txt file
				VLAN_NAME="Legacy/Unknown"
			fi
	  done < VLANS.txt  # <- the read command is reading this file
	fi


else  # No announcement produced within 90 seconds

	printf "\n"
	printf "No LLDP announcments detected!\n"
	printf "Check your connection\n\n"
	if [ $KEEP_CAP == 0 ]
	then

		rm -f "$PACK_TEMP_DEST""$PACK_DUMP"
	fi
	exit 2
fi


# Format everything nicely and informatively into a temp file
# If just writing to file, don't clear screen
if [ $WRT_FLAG == 0 ]
then

	if [ $VERBOSE == 0 ]
	then

		clear
	fi

fi


printf "\n"
printf "Host: $LONG_HOST\n" > "$RSLT_TEMP_DEST""$RSLT_FILE"
printf "Date: $DATE\n\n"    >> $"$RSLT_TEMP_DEST""$RSLT_FILE"

printf "Switch Name:          $SW_NAME \n\n" >> "$RSLT_TEMP_DEST""$RSLT_FILE"

printf "Switch IP Address:    $SW_IP_ADDR \n\n" >> "$RSLT_TEMP_DEST""$RSLT_FILE"

printf "Switch Port:          $SW_PORT_SHRT ($SW_PORT ) \n\n" >> "$RSLT_TEMP_DEST""$RSLT_FILE"

printf "Port VLAN ID:         $VLAN_ID ( $VLAN_NAME ) \n\n" >> "$RSLT_TEMP_DEST""$RSLT_FILE"


# Print the file contents to screen if not writing to file
if [ $WRT_FLAG == 1 ]
then

	mv "$RSLT_TEMP_DEST""$RSLT_FILE" "$RSLT_END_DEST""$RSLT_FILE"
	printf "Saved to $RSLT_END_DEST\n\n"
	exit 0
else

	cat "$RSLT_TEMP_DEST""$RSLT_FILE"
fi


### END Main Script Functions ###

#################################################################################

### START Save Options ###

# Prompt user if they would like to save the output

printf "Save results to file? (y/n) "
read yn

if echo $yn | grep -iq "^y"
then

	mv "$RSLT_TEMP_DEST""$RSLT_FILE" "$RSLT_END_DEST""$RSLT_FILE"
	printf "Saved to $RSLT_END_DEST\n\n"
else

	printf "\n\n"
	rm -f "$RSLT_TEMP_DEST""$RSLT_FILE"
fi

### END Save Options ###

# Remove the packet dump, unless specified to keep it
if [ $KEEP_CAP == 0 ]
then

	rm -f "$PACK_TEMP_DEST""$PACK_DUMP"
fi

### END OF SCRIPT ###############################################################
exit 0
