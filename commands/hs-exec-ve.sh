#!/bin/bash

if $onHS
then ## no identation.

## exec-all 'something' (or with "")ssh  
hint "exec-all 'CMD [..]'" "Execute a command on all running containers."
if [ "$CMD" == "exec-all" ]
then

argument comm

 for C in $(lxc-ls)
 do
        set_is_running

        if $is_running
        then
        ssh $C "$comm"
        fi

        get_ip
        get_pound_state
        get_state
        get_info

        echo ''        

 done

ok
fi

## exec-all backup-db
hint "exec-all-backup-db" "Execute a db backup on all running containers."
if [ "$CMD" == "exec-all-backup-db" ]
then

 for C in $(lxc-ls)
 do
        set_is_running

        if $is_running
        then
        ssh $C "srvctl backup-db"
        fi

        get_ip
        get_pound_state
        get_state
        get_info

        echo ''        

 done

ok
fi


fi
