#!/bin/bash

if $onVE && $isROOT
then ## no identation.

        hint "add-cms [CMS]" "Install a content managment system."
        if [ "$CMD" == "add-cms" ]
        then        
                argument CMS
            
                if [ -f $install_dir/ve-cms/$CMS.sh ]
                then
                    source $install_dir/ve-cms/$CMS.sh
                else
                    err "$CMS not found." 
                fi
            
        ok
        fi ## add-cms
fi

man '
    Use the github release of Joomla! Create configuration files.
    http://www.joomla.org/
'

