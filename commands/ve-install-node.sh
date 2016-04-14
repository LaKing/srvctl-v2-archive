if $onVE && $isROOT
then ## no identation.

        hint "install-node" "update install the latest node.js"
        if [ "$CMD" == "install-node" ]
        then
    
            install_nodejs_latest
    
        ok
        fi 

fi

man '
    Goes to nodesource, and checks updates installs the latest version.
'

