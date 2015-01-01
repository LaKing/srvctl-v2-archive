#!/bin/bash

hint "update-password [USERNAME]" "Update password based on .password file"
if [ "$CMD" == "update-password" ]
then

	_u=$(echo $CWD | cut -d '/' -f 3)
	
	if ! [ -d "/home/$_u" ] || [ -z "$_u" ] || ! [ -z "$2" ]
	then
		argument _u
	fi

	if [ -d "/home/$_u" ]
	then
		update_password $_u
	fi
ok
fi ## 
