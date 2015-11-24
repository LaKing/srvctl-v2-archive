#!/bin/bash

if $onVE && $isROOT
then ## no identation.

        hint "add-cms [CMS]" "Install a content managment system."
        if [ "$CMD" == "add-cms" ]
        then        
            
            argument cms
            
            if [ -f $install_dir/ve-cms/$cms.sh ]
            then
                source $install_dir/ve-cms/$cms.sh
            fi

        ok
        fi ## install-joomla
fi

man '
    Use the github release of Joomla! Create configuration files.
    http://www.joomla.org/
'

