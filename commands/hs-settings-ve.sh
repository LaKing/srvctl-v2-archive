#!/bin/bash

if $onHS
then ## no identation.

        hint "settings VE OPTION [disable]" "Set custom directives for a VE, or return to the defaults"
        if [ "$CMD" == "settings" ] && [ ! -z "$ARG" ]
        then        
            argument C
            sudomize
            authorize
                
            local _sf=$SRV/$C/settings/pound-$OPA
            if [ "$OPAS4" == "disable" ]
            then
                if [ -f $_sf ]
                then
                    msg "Removing $C configuration pound-$OPA"
                    rm -rf $_sf
                else
                    err "Configuration directive not found."
                    exit
                fi
            else
                
                ## bool type pound settings
                if [ "$OPA" == "no-http" ] || [ "$OPA" == "no-https" ]
                then                    
                    msg "Adding $C configuration pound-$OPA"
                    echo 'true' > $_sf
                fi
    
                ## numeric type pound settings
                if [ "$OPA" == "http-port" ] || [ "$OPA" == "https-port" ] && [ ! -z "$OPAS4" ]
                then
                    local _sf=$SRV/$C/settings/pound-$OPA
                    local _nm=$OPAS4
                    
                        if (( $_nm > 1024 )) && (( $_nm < 49151 ))
                        then
                            msg "Adding $C configuration for pound-$OPA"
                            echo $_nm > $_sf
                        else
                            err "Not a valid registered port number."
                        fi 

                fi
                
                
                ## string type pound setting
                if [ "$OPA" == "host" ] && [ ! -z "$OPAS4" ]
                then
                    local _sf=$SRV/$C/settings/pound-$OPA
                    local _st="$OPAS4"
        
                    if ! $(is_fqdn $_st)
                    then
                          err "$_st failed the domain regexp check. Exiting."
                          exit 10
                    fi

                    msg "Adding $C configuration pound-$OPA"
                    echo $_st > $_sf
                        
                fi
                
                ## string type pound setting
                if [ "$OPA" == "redirect" ] && [ ! -z "$OPAS4" ]
                then
                    local _sf=$SRV/$C/settings/pound-$OPA
                    local _st="$OPAS4"
                    
                    if [ "${_st:0:7}" != "http://" ] && [ "${_st:0:8}" != "https://" ]
                    then
                         _st="http://$_st"                       
                    fi      
                    
                    local _regex='(https|http)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'              

                    if [[ $_st =~ $regex ]]
                    then
                        msg "Adding $C -> $_st redirect directive"
                        echo $_st > $_sf
                    else
                        err "$_st is not a valid URL"
                    fi
                fi
            fi  
            
            ## create pound configuration files
            regenerate_pound_files
            #regenerate_pound_sync
            restart_pound
                    
            ok       
              
        fi ## cmd
fi

man '
    Set a custom directive for a VE. OPTIONS are:
    no-http - redirect all http traffic to https
    no-https - redirect all https traffic to http
    http-port NUMBER - serve http from a custom port
    https-port NUMBER - serve https from a custom port
    redirect URL - redirect incoming traffic to DOMAIN
'


