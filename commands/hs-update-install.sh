#!/bin/bash

if $isROOT
then ## no identation.

local _hintstr="This will update the current OS for a srvctl-configured containerfarm host installation."
if $onVE
then
    _hintstr="Update the container."
fi

hint "update-install [all]" "$_hintstr"
if [ "$CMD" == "update-install" ]
then
        
        msg "Update system."
        pm_update 
        msg "OK"

        if $onVE
        then
            msg "Exiting - onVE"
            ok
            exit 0
        fi

        if [ "$ARG" == "all" ]
        then
           all_arg_set=true
           ntc "Reinstalling ALL services."
        fi
        
        source $install_dir/hs-install/main.sh
 
msg "update-install done. You may regenerate configs now."

ok
fi ## update-install

man '
    This command will run the srvctl installation scripts, thus inicailize the host as a container-farm.
    With the [all] option set, all srvctl-related existing configurations will be regenerated, and updated. 
    In the first step, a blank configuration fill will be written to /etc/srvctl/config
    Following files are honored - if found:
         /root/crt.pem, /root/key.pem, /root/ca-bundle.pem - certificates for the host
         /root/saslauthd - a custom binary, that fixes the incompatibility between perdition and saslauthd
    A company domain name should be set in the config file, and a logo.png and a favicon.ico should be at that domain.
    Custom files for pound will reside in /var/www/html, and they might be customized.      
'
fi ## onHS







