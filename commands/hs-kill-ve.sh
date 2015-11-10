#!/bin/bash

if $onHS
then ## no identation.


## kill
hint "kill VE" "Force a container to stop."
if [ "$CMD" == "kill" ]
then
        argument C
        sudomize
        authorize
        
        set_is_running

        if $is_running
        then
                say_info "KILLING"
                get_info
                nfs_unmount $C
                lxc-stop -k -n $C    
        else
                get_state
                get_info       
        fi
        echo ''
ok
fi

man '
    This command executes lxc-stop -k, to halt a container. It is recommended to use a stop command before killing it.
    Rather than requesting a clean shutdown of the container, explicitly kill all tasks in the container.
'

## kill-all
hint "kill-all" "Force all containers to stop."
if [ "$CMD" == "kill-all" ]
then
        sudomize
    
        for C in $(lxc_ls)
        do
                set_is_running

                if $is_running
                then
                        say_info "KILLING"
                        get_info
                        nfs_unmount $C
                        lxc-stop -k -n $C                      
                else
                        get_state
                        get_info        
                fi
        echo ''
        done

ok
fi

man '
    This command executes lxc-stop -k, on all running containeres! It is recommended to use a stop / stop-all command before.
    Rather than requesting a clean shutdown of the containers, it will explicitly kill all tasks in all the containers.
'

fi

