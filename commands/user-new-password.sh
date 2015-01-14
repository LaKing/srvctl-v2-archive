#!/bin/bash

hint "new-password [USERNAME]" "Set a new password for user."
if [ "$CMD" == "new-password" ]
then

        _u=$(echo $CWD | cut -d '/' -f 3)
        
        if ! [ -d "/home/$_u" ] || [ -z "$_u" ] || ! [ -z "$2" ]
        then
                argument _u
        fi

        if [ -d "/home/$_u" ]
        then
                bak /home/$_u/.password
        
                get_password
                echo $password > /home/$_u/.password

                update_password $_u

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
