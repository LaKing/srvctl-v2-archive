if $isROOT
then ## no identation.
    
    if [ "$CMD" == "exec-function" ]
    then
        $OPAS
        ok
    fi

fi

if $onHS
then ## no identation.

hint "exec VE [CMD ..] | VE [CMD ..] " "Enter the root shell, or execute a command on a given container. This is the default command."

if [ "$CMD" == "exec" ]
then

    argument C
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
 
if [ -d "$SRV/$CMD/rootfs" ]
then

    C=$CMD
    
    sudomize
    authorize

    set_is_running
    if $is_running
    then
        if [ -z "$OPAS" ]
        then
            #ntc "Switching to $C .."
            lxc-attach -n $C 
            #ntc "Exiting $C .."
        else
            #ntc "[root@$C ~]# $OPAS3"
            lxc-attach -n $C -- $OPAS
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
    Users can access local containers directly. Syntax is similar to that of ssh.
    eg.: sc example.com do-something with arguments
'

fi

