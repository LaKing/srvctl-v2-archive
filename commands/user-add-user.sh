if $isROOT
then


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
            echo "This is the mailing system at $HOSTNAME, your account has been created." | mail -s "Welcome" $U
        fi
    fi
        
    if $onHS
    then
        C=$OPA
     
        add_user $U 
     
        if [ ! -z "$C" ] && [ -f "$SRV/$C/settings/users" ] 
        then
            has=false
            for _i in $(cat $SRV/$C/settings/users)
            do
                if [ "$U" == "$_i" ]
                then
                    $has=true
                fi
            done
            
            if ! $has
            then
                echo $U >> $SRV/$C/settings/users
                log "$SC_USER added $U to container $C"
            else
                msg "$U has access to container $C"
                exit
            fi
            
            regenerate_users_structure
        fi
    fi        
ok
fi ## adduser

fi ## isROOT

man '
    This command will set up a new user account. It will generate a password, and password hashes for VE applications.
    A single user may have access to all containers and their CMSs, with the same password. The generated password is stored in plaintext.
'





