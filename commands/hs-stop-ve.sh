#!/bin/bash

if $onHS
then ## no identation.


## stop
hint "stop VE" "Stop a container." 
man '
    Stop a container via shh and shutdown. It will also unmount NFS shares.
'


hint "disable VE" "Stop and disable container." 
man '
    Stop a container via shh and shutdown. It will also unmount NFS shares.
    Disabling it will prevent it from starting it with the start-all command.
'

if [ "$CMD" == "stop" ] || [ "$CMD" == "disable" ]
then

        argument C
        sudomize
        authorize

        nfs_unmount $C

        set_is_running

        if $is_running
        then
                printf ${yellow}"%-10s"${NC} "SHUTDOWN"
                say_name $C
                nfs_unmount $C
                ssh $C shutdown -P now
        else 
                get_state
                say_name $C
        fi

        
        if [ "$CMD" == "disable" ]
        then
                echo $NOW > $SRV/$C/settings/disabled
        fi
        echo ''     
        
        regenerate_known_hosts           

ok
fi ## stop

## stop-all
hint "stop-all" "Stop all containers." 
if [ "$CMD" == "stop-all" ]
then
    
    sudomize
        for C in $(lxc_ls)
        do
            nfs_unmount $C
        done 
        
        for C in $(lxc_ls)
        do
                set_is_running

                if $is_running
                then
                        printf ${yellow}"%-10s"${NC} "SHUTDOWN"
                        say_name $C
                        ssh $C shutdown -P now &
                else 
                        get_state
                        say_name $C
                fi

                echo ''        

        done
        
        container_running=true  
        while $container_running
        do
            container_running=false
            sleep 10       
            msg "Waiting for all containers to stop .."
            for C in $(lxc_ls)
            do
                info=$(lxc-info -s -n $C)
                state=${info:16}

                if [ "$state" == "RUNNING" ]
                then
                    echo $C
                    container_running=true
                fi
            done
        
        done        
    msg "... done"
    regenerate_known_hosts
ok
fi ## stop-all

man '
    Stop all containers via shh and shutdown. It will also unmount NFS shares.
'

fi



