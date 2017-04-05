#!/bin/bash
clear

echo '__          __             __
\ \_________\ \____________\ \___
 \  _ \  _\ _  \  _\ __ \ __\   /
  \___/\__/\__/ \_\ \___/\__/\_\_\

The following actions are available
'
  if [ ! -d scripts ]
  then
	  echo "Unable to find files. Working directory must contain this script"
  else
	  if [ -e tar/bedrock_linux_1.0beta2_nyla.tar ]
	  then
		  echo '  1) Download and build'
		  tput setaf 2
		  echo ' *2) Install bedrock (All files detected and ready to install)'
		  tput sgr0
	  else
		  tput setaf 2
		  echo ' *1) Download and build'
		  tput sgr0
		  echo '  2) Install bedrock (no files detected for install)'
	  fi
	  looping=1
	  while [ $looping == 1 ]
	  do
		  read -p "Enter the step you want to complete: " step
		  if [ $step == 1 ]
		  then
			  looping=0
			  scripts/downloadBedrock.sh
		  elif [ $step == 2 ]
		  then
			  looping=0
			  sudo scripts/installBedrock.sh
		  else
			  echo "invalid option"
		  fi
	  done
  fi

