#!/bin/bash

if ! $isUSER
then

hint "new-password [USERNAME]" "Set a new password for user."
if [ "$CMD" == "new-password" ]
then

        U=$(echo $CWD | cut -d '/' -f 3)
        
        if ! [ -d "/home/$U" ] || [ -z "$U" ] || ! [ -z "$2" ]
        then
                argument U
        fi

        if [ -d "/home/$U" ]
        then
                bak /home/$U/.password
        
                get_password
                echo $password > /home/$U/.password

                update_password $U

                if $onVE
                then 
                        ## TODO check this
                        echo "This is the mailing system at "$(hostname)", your password has been updated." | mail -s "Notice" $U
                fi
        fi
ok
fi

man '
    Set a new user password, and regenerate user password hashes.
'
## TODO, regenerate/update container configs

fi
