#!/bin/bash

## If user is root or runs on root privileges, continiue. 
## (TODO: userspace implementation)
if [ "$UID" -ne "0" ]
then
  echo "Root privileges needed to run this script."
  ## Attemt to get root privileges with sudo, and run the script
  ## sudo bash $0 $1 $2 $3 $4 $5 $6 $7 $8 $9
  exit
fi
