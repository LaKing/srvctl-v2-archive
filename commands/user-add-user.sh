#!/bin/bash
if $onHS
then
    hint "add-user USERNAME [VE]" "Add a new user to the system. Optionally, grant the user access to VE."
else
    hint "add-user USERNAME" "Add a new user to the system."
fi

if [ "$CMD" == "add-user" ]
then

    argument U
    
    if $onVE
    then
        add_user $U
    
        if [ ! -d "/home/$U/Maildir" ]
        then 
            ## initialize maildir
            echo "This is the mailing system at "$(hostname)", your account has been created." | mail -s "Welcome" $U
        fi
    fi
        
    if $onHS
    then
        C=$OPA
        
        sudomize
        authorize
     
        add_user $U 
     
        if [ -f "$SRV/$C/users" ] 
        then
            has=false
            for _i in $(cat $SRV/$C/users)
            do
                if [ "$U" == "$_i" ]
                then
                    $has=true
                fi
            done
            
            if ! $has
            then
                echo $U >> $SRV/$C/users
                echo "$SC_SUDO_USER +> $C" >> /home/$U/.parent_users
                log "$SC_SUDO_USER added $U to container $C"
            else
                msg "$U has access to container $C"
                exit
            fi
            
            regenerate_users_structure
        fi
    fi        
ok
fi ## adduser

man '
    This command will set up a new user account. It will generate a password, and password hashes for VE applications.
    A single user may have access to all containers and their CMSs, with the same password. The generated password is stored in plaintext.
'

