#!/bin/bash

if $onHS
then

hint "add-publickey [keyfile]" "Add an ssh-rsa public key."

if [ "$CMD" == "add-publickey" ]
then

    tmp_file=$TMP/$USER-srvctl-import.key

    if [ -z "$ARG" ]
    then
        rm -rf $tmp_file
        msg "Please paste publickey. (id_rsa.pub)"
        while read line
        do
            # break if the line is empty
            if [ -z "$line" ]
            then 
                break
            fi
            echo "$line" >> $tmp_file
        done
    else
        if [ -z "$SC_SUDO_USER" ]
        then
            msg "Import public key from file-path."
        fi
        
        tmp_file=$ARG

        if [ ! -f "$ARG" ]
        then
            tmp_file=$CWD/$ARG
        fi
    
        if [ ! -f "$tmp_file" ]
        then
            err "File not found. $tmp_file"
            exit
        fi
    fi
    
    if $isUSER
    then
        sudo $install_dir/srvctl-sudo.sh add-publickey $tmp_file
        exit
    else 
        
        ## TODO check public key format, eg ssh-rsa AAAB..xyz comment@sd
        ## TODO append comment
        
        if [ -z "$SC_SUDO_USER" ]
        then
            cat $tmp_file >> /root/.ssh/authorized_keys
            msg "Key added to root's authorized keys."
        else
            cat $tmp_file >> /root/srvctl-users/authorized_keys/$SC_SUDO_USER
            msg "Key added to $SC_SUDO_USER"
        fi
    fi    
    
    regenerate_users_structure
    
    rm -rf $tmp_file

fi

fi # onHS
