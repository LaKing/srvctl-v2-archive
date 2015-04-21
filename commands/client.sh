#!/bin/bash

if [ "$CMD" == "client-noop" ]
then
ok
fi

if $isUSER
then 
    hint "client" "Run the srvctl client to connect to other servers."
    if [ "$CMD" == "client" ]
    then
        bash $install_dir/srvctl-client.sh ${ARGS:7}
    fi
fi
