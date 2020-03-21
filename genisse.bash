#!/bin/bash
#set -x

VERSION="15/03/2020 19:30"

DEFAULT_FILE_EXTENSION=".txt"

declare -a FILE_LIST_ARRAY # declare variable as array

# logo for genisse
function displayGenisseLogo() 
{
cat << EOLogo

                                 (\__/)
                                 /O  O\ 
                                (  °°  )
                                 ------
EOLogo

}

function displayInteractiveCommandBanner() 
{
	# for frame characters,see https://theasciicode.com.ar/extended-ascii-code/box-drawing-character-single-line-lower-left-corner-ascii-code-192.html

cat << EOInteractiveCommandBanner

	┌─────────────────────────────────┐
	│  Help for interactive commands  │
	└─────────────────────────────────┘
	
EOInteractiveCommandBanner

}

# usage for command line
function displayUsage() 
{
cat << EOUsage

usage: ./`basename $0` [OPTIONS...]

Genisse (Generic Interactive Script Skeleton used as an Example) 
is a useless but smart base to build your interactive bash scripts.

Example: ./`basename $0` -f myCommands.txt
	Execute commands from file.

OPTIONS
	-e <ext>	Set extension for file search. Default: '${DEFAULT_FILE_EXTENSION}'.
	-h		Display this help for line argument options.
EOUsage

	displayGenisseLogo
	sleep 1
	
	displayInteractiveCommandBanner
	displayInteractiveUsage
}


# help for interactive command prompt 
function displayInteractiveUsage() {
cat << EOInteractiveUsage
	ex[tension] [<ext>]	Set or display extension for file search.
	ls			List files for defined extension

	q[uit]			Quit prompt command.
	h[elp]     		Displays this help for interactive commands.
	
EOInteractiveUsage
}


# Message for unknown command
function unknownCommand() {
	echo
	echo "WARNING: Unknown command: '$1'"
	echo "Please type 'h' for help."
}

# set or remove file extension for search
function setExtension() {
	FILE_EXTENSION=$1
	echo
	echo "FILE_EXTENSION=$FILE_EXTENSION"
}


# process command to set or remove file extension for search
function processExtensionCommand() {
	# first parameter ignored for call in command loop
	shift
	
	if [ $# -gt 0 ]; then
		# set extension with argument
		if [[ $1 =~ ^\. ]]; then
			setExtension $1
		else
			# add leading '.' for extension
			setExtension .$1
		fi
	fi
}


#
# Utility functions for Arrays management
# ---------------------------------------

# transform a list into 
function getArrayFromList() {
	
	echo $@ | awk '
BEGIN {
	RS=" "
	printf "("
}
{
	gsub(/\n$/, "", $0) # remove trailing carriage return
	printf "\x27" $0 "\x27 "
}
END {
	printf ")" 
}
'

}

# check function result and return array from results if no error
function checkResultThenGetArrayFromList() {
	command="$1"
	commandResult=`${command} 2> /dev/null`
	commandReturnCode=$?
	
	# error or not error?
	if [ $commandReturnCode -eq 0 ]; then
		getArrayFromList $commandResult
	else
		# no value: empty result
		echo "( )"
	fi
}


# list array elements
function displayArrayElementsWithIndex() {
	declare -a arrayDisplay=("${!1}") # warning: do not use existing variable name
	declare -i index
		
	if [[ ${#arrayDisplay[@]} > 0 ]]; then
		for index in $(seq 0 $((${#arrayDisplay[@]}-1)) ) ; do
			echo "	$((${index} + 1)): ${arrayDisplay[$index]}"
		done
	else
		echo "	No value for this command"
	fi
}

# process command for given item
# param 1: array od data
# param 2: index of item to process
function processCommandOnArrayItem() {
	declare -a arrayProcess=("${!1}") # warning: do not use existing variable name
	paramIndex=$2
	itemIndex=$(($paramIndex - 1))
	
	# control context	
	if [ ${#arrayProcess[@]} -eq 0 ]; then
		echo "	No value for this command"
	elif [ $paramIndex -le 0 ]; then
		echo "ERROR: Index out of bounds. Min index=1"
		displayArrayElementsWithIndex arrayProcess[@]
	elif [ $paramIndex -gt ${#arrayProcess[@]} ]; then
		echo "ERROR: Index out of bounds. Max index=${#arrayProcess[@]}"
		displayArrayElementsWithIndex arrayProcess[@]
	else
#		echo "${paramIndex}: ${arrayProcess[$itemIndex]}"
		ls -ls ${arrayProcess[$itemIndex]}
	fi
}

#
# End of Utility functions for Arrays management
# ----------------------------------------------





#
# Functions for command processing
# --------------------------------


# list files for given extension
function processListFilesCommand() {
	# first parameter ignored for call in command loop
	shift

	command="ls *${FILE_EXTENSION}"	

	# store information in an array
	declare -g FILE_LIST_ARRAY=$(checkResultThenGetArrayFromList "$command")
	
	echo
	# process command for item number if given
	if [ $# -gt 0 ]; then
		processCommandOnArrayItem FILE_LIST_ARRAY[@] $1
	else
		displayArrayElementsWithIndex FILE_LIST_ARRAY[@]
	fi
	
	echo
	echo "FILE_EXTENSION=$FILE_EXTENSION, size=${#FILE_LIST_ARRAY[@]}"
}

# initialize context
function initializeContext() {
	echo
	setExtension $DEFAULT_FILE_EXTENSION
}


# initialize context
initializeContext

# read and procees line argument parameters
while getopts "he:" option
do
	case $option in
		h)
			displayUsage
			exit 0
			;;
			
		e)
			processExtensionCommand "scriptArg" ${OPTARG}
			;;
		esac
done
shift $((OPTIND-1))

# welcome message
echo
echo "Welcome to `basename $0`"
displayGenisseLogo

# loop for command input and processing
function waitForCommand() {
	# command controleur for user
	echo
	while true; do
		echo
		read -p "Your command $ " command
		case $command in
			# file extension
			ex* )
				processExtensionCommand $command
				;;
				
			# list files
			ls* )
				processListFilesCommand $command
				;;
				
			# Control commands:
			q* ) break;;

			[hH]* )	displayInteractiveUsage;;
			
			# unknown command
			* ) unknownCommand "$command";;

		esac
	done
}


# command loop for user
waitForCommand


echo
echo "Bye!"