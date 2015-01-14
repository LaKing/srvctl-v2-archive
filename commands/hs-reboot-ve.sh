#!/bin/bash

if $onHS
then ## no identation.


## reboot VE
hint "reboot VE" "Restart a container."
if [ "$CMD" == "reboot" ]
then
        argument C

        set_is_running

        if $is_running
        then
                printf ${yellow}"%-10s"${NC} "REBOOT!"
                get_info

                nfs_unmount
                  ssh $C reboot        
                wait_for_ve_connection $C
                  nfs_share
        else 
                get_state
                get_info        
                echo ''
        fi
        
ok
fi

man '
    This command will reboot the VE, by executing reboot in the container - via ssh.
    If ther container is not accessible over ssh, it can be manually stopped with lxc-stop or killed with srvctl.
    Rebooting a container with srvctl will remount NFS shares.   
'

## reboot all
hint "reboot-all" "Restart all containers."
if [ "$CMD" == "reboot-all" ]
then

        for C in $(lxc-ls)
        do

                set_is_running

                if $is_running
                then
                        printf ${yellow}"%-10s"${NC} "REBOOT!"
                        get_info

                        nfs_unmonut
                        ssh $C reboot        
                        wait_for_ve_connection $C
                        nfs_share
                else 
                get_info
                get_state
                fi

                echo ''        
        done

ok
fi

man '
    This command will reboot all VEs, by executing reboot in all the containers one by one, via ssh.
    If ther container is not accessible over ssh, it can be manually stopped with lxc-stop or killed with srvctl.
    Rebooting containers with srvctl will remount NFS shares.   
'

fi
