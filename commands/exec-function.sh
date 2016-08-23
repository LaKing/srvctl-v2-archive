if $isROOT
then ## no identation.
    
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

fi



