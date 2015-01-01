#!/bin/bash

hint "add-user USERNAME" "Add a new user to the system."
if [ "$CMD" == "add-user" ]
then

	argument U

	add_user $U

	if $onVE
	then 
		## TODO check this
		echo "This is the mailing system at "$(hostname)", your account has been created." | mail -s "Welcome" $U
	fi
ok
fi ## adduser

