#!/bin/bash

if $onHS
then ## no identation.


## start
hint "start VE" "Start a container."
if [ "$CMD" == "start" ]
then
        
        
        argument C
        sudomize
        authorize
        
        set_file_limits
        rm -rf $SRV/$C/settings/disabled

        set_is_running
        
        if [ ! -f $SRV/$C/settings/disabled ] && ! $is_running
        then
                lxc_start $C
        else
                get_state
                say_name $C
                
        fi        
        echo ''

ok
fi

man '
    Start the VE. If the container was disabled, it will be enabled.
    The NFS share will be mounted on the hosts home folders for the configured users.
'

## startall
hint "start-all [delay]" "Start all containers and services. Optionally with a delay in-between."
if [ "$CMD" == "start-all" ]
then
        sudomize
        local _delay=0
        
        
        if [ ! -z $OPA ]
        then
            _delay=$OPA
        fi
        
        set_file_limits

        for C in $(lxc_ls)
        do
                sleep $_delay
        
                set_is_running
        
                if [ ! -f $SRV/$C/settings/disabled ] && ! $is_running
                then
                        lxc_start $C
                else
                        get_state
                        say_name $C
                        
                fi        

                echo ''
        done
ok
fi

man '
    Start all, except the disabled containers. It will also mount NFS shares.
    This operation is relative CPU-intensive, and depending on the number of containers it may take several minutes.
    The delay parameter can be used to slow-down the process. Default is 1 sec.
'

fi




