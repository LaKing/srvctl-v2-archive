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

man '
    The client scripts allows srvctl users, or better said their clients to use a script on their workstations.
    It is Linux, Mac and Windows compatible via git bash or equivalent. It can be used to upload / download, sync files,
    and to map ports to direct ssh root access to containers. It can work in an interactive mode.
'
