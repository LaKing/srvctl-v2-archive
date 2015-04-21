#!/bin/bash
if ! $isUSER
then

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

man '
    This command will set up a new user account. It will generate a password, and password hashes for VE applications.
    A single user may have access to all containers and their CMSs, with the same password. The generated password is stored in plaintext.
    Only the root user of the host can add ssh public keys for users.
'
## TODO redesign publickey storage.

fi
