#!/bin/bash

if $onHS
then ## no identation.


## reboot VE
hint "reboot VE" "Restart a container."
if [ "$CMD" == "reboot" ]
then
        argument C
        sudomize
        authorize

        set_is_running

        if $is_running
        then
                say_info "REBOOT!"
                say_name $C

                nfs_unmount $C
                  ssh $C reboot 2> /dev/null              
                wait_for_ve_online $C
                  nfs_mount $C
        else 
                get_state
                say_name $C        
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

        sudomize

        for C in $(lxc_ls)
        do

                set_is_running

                if $is_running
                then
                        say_info "REBOOT!"
                        say_name $C

                        nfs_unmount $C
                        ssh $C reboot 2> /dev/null      
                        wait_for_ve_connection $C
                        nfs_mount $C
                else 
                get_state
                say_name $C
                
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


