#!/bin/bash

if ! $isUSER
then

hint "update-password [USERNAME]" "Update password based on .password file"
if [ "$CMD" == "update-password" ]
then

        U=$(echo $CWD | cut -d '/' -f 3)
        
        if ! [ -d "/home/$U" ] || [ -z "$U" ] || ! [ -z "$2" ]
        then
                argument U
        fi

        if [ -d "/home/$U" ]
        then
                update_password $U
        fi
ok
fi ## 

man '
    The USERNAME parameter is required if the current working directory is not a home folder.
'

fi
