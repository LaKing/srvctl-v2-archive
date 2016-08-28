#if $isROOT
#then ## no identation.
    hint "exec-function COMMAND" "Execute a function in srvctl."
    if [ "$CMD" == "exec-function" ]
    then
        $OPAS
        local _xit=$?
        if [ "$_xit" != 0 ]
        then
            err "exec-function returned with exit-code $_xit"
        fi
        ok
    fi

man ' 
    It is possible to execute a command or a srvctl-function after bootstraping srvctl. 
    Thus, srvctl configs, constants, variables, and funcions are available.
'

    hint "exec-on-hosts COMMAND" "Execute a command on every srvctl host accessible."
    if [ "$CMD" == "exec-on-hosts" ]
    then
        msg $OPAS
        $OPAS
        local _xit=$?
        if [ "$_xit" != 0 ]
        then
            err "exec-on-$HOSTNAME returned with exit-code $_xit"
        fi
        
        for _S in $SRVCTL_HOSTS
        do
            msg "ssh $_S '$OPAS'"
            ssh $_S $OPAS
            local _xit=$?
            if [ "$_xit" != 0 ]
            then
                err "exec-on-$_S returned with exit-code $_xit"
            fi
        done
        
        ok
    fi

man '
    Since several srvctl hosts may be available, this command will execute it on all hosts.
    The command is executed on the host itself, and on all remote hosts.
'

#fi



