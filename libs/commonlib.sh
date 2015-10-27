## functions common to all areas of srvctl

function load_libs {

    for libfile in $install_dir/libs/*
    do
        source $libfile
    done
}

function load_commands {
    
    for sourcefile in $install_dir/commands/*
    do
        source $sourcefile
    done
    
    if [ -d /root/srvctl-includes ]
    then
        for sourcefile in /root/srvctl-includes/*
        do
            source $sourcefile
        done
    fi
    
}
function hint_commands {
    for sourcefile in $install_dir/commands/*
    do
        source $sourcefile
        hint
    done
        
    if [ -d /root/srvctl-includes ]
    then
        for sourcefile in /root/srvctl-includes/*
        do
            source $sourcefile
            hint
        done
    fi
}

