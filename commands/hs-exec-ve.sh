#!/bin/bash
if $onHS
then

## exec-all 'something' (or with "")ssh  
hint "exec-all 'CMD [..]'" "Execute a command on all running containers of this host."
if [ "$CMD" == "exec-all" ]
then

    if [ -z "$ARG" ]
    then
        err "No command specified to execute on containers."
        exit
    fi
    sudomize 
    
        for C in $(lxc_ls)
        do                 
            set_is_running
            get_ip
            get_pound_state
            get_state
            say_name $C
            echo ''        
            if $is_running
            then
                ## execute everything after the "exec-all" part of the argument
                ssh root@$C "$OPAS"                   
                if [ ! "$?" == "0" ]
                then
                    err "Command returned an error."
                fi
            fi
            echo ''
        done
    ok
fi

man '
    It is possible to iterate trough all running containers, and run a command.
    The command will be executed via ssh, as root, starting in the /root folder.
    Enclose the command into a string to use certain operators, like &&
'

fi



