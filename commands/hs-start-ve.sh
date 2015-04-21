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
        rm -rf $SRV/$C/disabled

        set_is_running
        
        if [ ! -f $SRV/$C/disabled ] && ! $is_running
        then
                lxc-start -o $SRV/$C/lxc.log -n $C -d
                say_info "STARTED"        
                get_info
                wait_for_ve_connection $C
                nfs_share
        else
                get_state
                get_info
                
        fi        
        echo ''

ok
fi

man '
    Start the VE. If the container was disabled, it will be enabled.
    The NFS share will be mounted on the hosts home folders for the configured users.
'

## startall
hint "start-all" "Start all containers and services."
if [ "$CMD" == "start-all" ]
then
        sudomize

        set_file_limits

        for C in $(lxc_ls)
        do
                set_is_running
        
                if [ ! -f $SRV/$C/disabled ] && ! $is_running
                then
                        lxc-start -o $SRV/$C/lxc.log -n $C -d
                        say_info "STARTED"        
                        get_info
                        wait_for_ve_connection $C
                        nfs_share
                else
                          get_state
                        get_info
                        echo ''
                fi        

                echo ''
        done

ok
fi

man '
    Start all, except the disabled containers. It will also mount NFS shares.
    This operation is relative CPU-intensive, and depending on the number of containers it may take several minutes.
'

fi
