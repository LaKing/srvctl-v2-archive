#!/bin/bash

if $onHS
then ## no identation.

hint "exec VE [CMD ..] | VE [CMD ..] " "Enter the root shell, or execute a command on a given container. This is the default command."

if [ "$CMD" == "exec" ] || [ -d "$SRV/$CMD/rootfs" ]
then

    if [ -d "$SRV/$CMD/rootfs" ]
    then
        C=$CMD
    else
        argument C
    fi
    
    sudomize
    authorize

    set_is_running
    if $is_running
    then
        if [ -z "$OPA" ]
        then
            #ntc "Switching to $C .."
            lxc-attach -n $C 
            #ntc "Exiting $C .."
        else
            #ntc "[root@$C ~]# $OPAS3"
            lxc-attach -n $C -- $OPAS3
            if [ "$?" != "0" ]
            then
                err "Command returned an error. $?"
            fi
            
        fi
    else 
        err "$C is STOPPED"
    fi
ok
fi
 
 
man '
    Users can access local containers directly. Syntax is similar to that of ssh. eg.: 
        sc example.com
        sc example.com "do-something with arguments"
'



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



