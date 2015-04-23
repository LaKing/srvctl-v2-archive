#!/bin/bash



function man {
    echo 1 > /dev/null
}

if [ "$UID" -ne "0" ]
then
    if $LXC_SERVER
    then
        ## Authorize this user!
        LOG="$(realpath ~)/.srvctl.log"
        isUSER=true
        #exit
    else    
        ## we only run the client script. 
        if (( "$UID" < 1000 ))
        then
            echo "Permission denied for system user: $(whoami)"
        else
            echo "Running the srvctl-client now!"
            source $install_dir/srvctl-client.sh $1
        fi
        exit
    fi
else
    isROOT=true
fi


## other wise, root can continiue.
