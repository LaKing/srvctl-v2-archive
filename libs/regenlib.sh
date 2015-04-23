#!/bin/bash

if $onHS
then ## no identation.

### regenerate-related functions

function regenerate_sudo_configs {
 
    sudoconf=/etc/sudoers.d/srvctl
    echo "## srvctl-regenerated sudo file" > $sudoconf
    echo '' >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add *" >> $sudoconf   
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh exec-all *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh exec-all-backup-db" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh kill *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh kill-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh reboot *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh reboot-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh remove *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh start *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh start-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh stop *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh stop-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh disable *" >> $sudoconf
      
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh status" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh status-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh status-usage" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh import-crt *" >> $sudoconf    
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh import-ca *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add-user *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add-publickey *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh show-csr *" >> $sudoconf
}


function regenerate_config_files {

        ## scan for imported containers         
        for _C in $(ls $SRV)
        do            

            if ! $(is_fqdn $_C)
            then
              continue
            fi
            
            if [ -f "$SRV/$_C" ]
            then
              continue
            fi
            
            if  [ ! -f $SRV/$_C/rootfs/etc/hostname ]
            then
              continue
            else
              echo $_C > $SRV/$_C/rootfs/etc/hostname
            fi
           
            
            if [ ! -f $SRV/$_C/config.counter ]
            then
                ## increase the counter
                counter=$(($(cat /etc/srvctl/counter)+1))
                echo $counter >  /etc/srvctl/counter
                echo $counter > $SRV/$_C/config.counter
            fi
            
            if [ ! -f $SRV/$_C/config.ipv4 ] || [ ! -f $SRV/$_C/config ] || $all_arg_set
            then
                    generate_lxc_config $_C
            fi
       
        done
        
        ## regenerate recognised containers
        for _C in $(lxc-ls)
        do

                if [ ! -f $SRV/$_C/config.counter ]
                then
                        err "No config.counter for $_C!"
                fi

                if [ ! -f $SRV/$_C/config.ipv4 ] || [ ! -f $SRV/$_C/config ] || $all_arg_set
                then
                        generate_lxc_config $_C
                fi

                if [ ! -f $SRV/$_C/users ]
                then
                        echo '' > $SRV/$_C/users 
                fi

                ##_ip=$(cat $SRV/$_C/config.ipv4)        

        done
}


function regenerate_etc_hosts {
        ## and relaydomains

        msg "regenerate etc_hosts" ## fist in $TMP
        echo '# srvctl generated' > $TMP/hosts
        echo '127.0.0.1                localhost.localdomain localhost' >> $TMP/hosts
        echo '::1                localhost6.localdomain6 localhost6' >> $TMP/hosts
        echo '' >> $TMP/hosts
        echo '' > $TMP/relaydomains

        for _C in $(lxc-ls)
        do

                ip=$(cat $SRV/$_C/config.ipv4)
                

                if [ -z $ip ] 
                then
                        counter=$(cat $SRV/$_C/config.counter)
                        if [ -z $counter ] 
                        then        
                                err "No counter, no IPv4 for "$_C
                        else
                                ip="10.10."$(to_ip $counter)
                        fi        
                fi

                if [ ! -z $ip ]
                then
 
                         echo $ip'                '$_C >>  $TMP/hosts
                        echo $ip'                mail.'$_C >>  $TMP/hosts
                        echo $_C' #' >>  $TMP/relaydomains

                                if [ -f /$SRV/$_C/aliases ]
                                then
                                        for A in $(cat /$SRV/$_C/aliases)
                                        do
                                                if [ "$A" == "$(hostname)" ]
                                                then
                                                        ntc "$_C alias: $A - is the host itself!"
                                                else
                                                        # ntc "$A is an alias of $_C"
                                                           echo $ip'                '$A >>  $TMP/hosts
                                                          echo $ip'                mail.'$A >>  $TMP/hosts
                                                        echo $A' #' >>  $TMP/relaydomains
                                                fi
                                        done
                                fi

                        echo ''  >>  $TMP/hosts


                fi
        done ## regenerated etc_hosts

        bak /etc/hosts
        rsync -a $TMP/hosts /etc

        bak /etc/postfix/relaydomains
        rsync -a $TMP/relaydomains /etc/postfix/relaydomains
        postmap /etc/postfix/relaydomains

} 

function scan_host_key {

        ## argument: Container
        ntc "Scanning host key for "$1

        ## TODO in the next line the container name may be better if not indicated.
        echo "## srvctl host-key" > $SRV/$1/host-key
        ssh-keyscan -t rsa -H $(cat $SRV/$1/config.ipv4) >> $SRV/$1/host-key 2>/dev/null
        ssh-keyscan -t rsa -H $1 >> $SRV/$1/host-key 2>/dev/null
        echo '' >> $SRV/$1/host-key        
                                
}

function regenerate_known_hosts {

        msg "regenerate known hosts"

        echo '## srvctl generated ..' > /root/.ssh/srvctl_hosts
         
        for _C in $(lxc-ls)
        do
                if [ ! -f $SRV/$_C/host-key ] || $all_arg_set
                then

                        set_is_running $_C
                        if $is_running
                        then

                                scan_host_key $_C
                        else
                                 ntc "VE is stopped, could not scan host-key for: "$_C
                                ## host        key is needed for .ssh/known-hosts
                        fi
                        
                                        
                fi

                if [ -f $SRV/$_C/host-key ]
                then
                        cat $SRV/$_C/host-key >> /root/.ssh/srvctl_hosts
                fi

        done ## regenerated  containers hosts
        
        echo '## .. srvctl generated' >> /root/.ssh/srvctl_hosts

        ## apply srvctl-known_hosts to root
        if [ -f /root/.ssh/own_hosts ]
        then
                cat /root/.ssh/own_hosts > /root/.ssh/known_hosts
                cat /root/.ssh/srvctl_hosts >> /root/.ssh/known_hosts
        else
                cat /root/.ssh/srvctl_hosts > /root/.ssh/known_hosts
        fi
        msg "Set known_hosts done."
}


function regenerate_pound_files {

        msg "regenerate pound files"

        rm -rf /var/pound
        mkdir -p /var/pound

        ## We will use a sort of layering, with up to 8 layers. 
        
        ## We assume that /etc/pound.cfg has two includes ...
        echo $MSG > /var/pound/http-includes.cfg
        echo $MSG > /var/pound/https-includes.cfg
        echo $MSG > /var/pound/https-certificates.cfg

        echo $MSG > /var/pound/http-domains.cfg
        echo $MSG > /var/pound/http-dddn-domains.cfg

        echo $MSG > /var/pound/http-8-domains.cfg
        echo $MSG > /var/pound/http-7-domains.cfg
        echo $MSG > /var/pound/http-6-domains.cfg
        echo $MSG > /var/pound/http-5-domains.cfg
        echo $MSG > /var/pound/http-4-domains.cfg
        echo $MSG > /var/pound/http-3-domains.cfg
        echo $MSG > /var/pound/http-2-domains.cfg
        echo $MSG > /var/pound/http-1-domains.cfg

        echo $MSG > /var/pound/https-domains.cfg
        echo $MSG > /var/pound/https-dddn-domains.cfg

        echo $MSG > /var/pound/https-8-domains.cfg
        echo $MSG > /var/pound/https-7-domains.cfg
        echo $MSG > /var/pound/https-6-domains.cfg
        echo $MSG > /var/pound/https-5-domains.cfg
        echo $MSG > /var/pound/https-4-domains.cfg
        echo $MSG > /var/pound/https-3-domains.cfg
        echo $MSG > /var/pound/https-2-domains.cfg
        echo $MSG > /var/pound/https-1-domains.cfg

        echo 'Include "/var/pound/https-certificates.cfg"' >> /var/pound/https-includes.cfg

        echo 'Include "/var/pound/http-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-dddn-domains.cfg"' >> /var/pound/http-includes.cfg        
        
        echo 'Include "/var/pound/http-8-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-7-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-6-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-5-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-4-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-3-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-2-domains.cfg"' >> /var/pound/http-includes.cfg
        echo 'Include "/var/pound/http-1-domains.cfg"' >> /var/pound/http-includes.cfg

        echo 'Include "/var/pound/https-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-dddn-domains.cfg"' >> /var/pound/https-includes.cfg

        echo 'Include "/var/pound/https-8-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-7-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-6-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-5-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-4-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-3-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-2-domains.cfg"' >> /var/pound/https-includes.cfg
        echo 'Include "/var/pound/https-1-domains.cfg"' >> /var/pound/https-includes.cfg



        ## $_C is the local version of $C
        for _C in $(lxc-ls)
        do
                if [ ! -d "$SRV/$_C/cert" ]
                then
                    create_certificate $_C
                fi

                # echo "@ "$_C
                cfg_dir=/var/pound/$_C
                mkdir -p $cfg_dir

                mkdir -p $SRV/$_C/cert
                cp -r $SRV/$_C/cert $cfg_dir

                for d in $( find $cfg_dir/cert -maxdepth 1 -type d )
                do

                        ### Import each certificate if test passes

                        # echo "# "$d
                        if [ ! -f $d/pound.pem ]
                        then
                                ## No ready-to-go pound.pem found, attemting to generate one. 
                                
                                ## either from some.key and some.crt 
                                cat $d/*.crt 2> /dev/null >> $d/pound.pem
                                echo '' >> $d/pound.pem
                                cat $d/*.key 2> /dev/null >> $d/pound.pem
                                echo '' >> $d/pound.pem
                                
                                ## or from a concrete key.pem and crt.pem
                                cat $d/crt.pem 2> /dev/null >> $d/pound.pem
                                echo '' >> $d/pound.pem
                                cat $d/key.pem 2> /dev/null >> $d/pound.pem
                                echo '' >> $d/pound.pem
                                
                                ## and a ca-bundle.
                                cat $d/ca-bundle.pem 2> /dev/null >> $d/pound.pem        
                        fi
                        
                        ## As the update-install process adds the ca-bundle, we can check against it ...
                        cert_status_ca=$(openssl verify -CAfile /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt $d/pound.pem 2> /dev/null | tail -n 1 | tail -c 3)
                        ## Or check for self-signed / or cert that contains the ca-files itself.
                        cert_status_ss=$(openssl verify $d/pound.pem $d/pound.pem 2> /dev/null | tail -n 1 | tail -c 3)

                        if [ "$cert_status_ca" == "OK" ] || [ "$cert_status_ss" == "OK" ] 
                        then 
                                # echo "VALID CERT FOUND"
                                echo 'Cert "'$d'/pound.pem"' >> /var/pound/https-certificates.cfg
                        else
                                # echo "CERT INVALID"
                                bak $d/pound.pem
                                rm -rf $d/pound.pem
                        fi

                done

                ## create configs
                _ip=$(cat $SRV/$_C/config.ipv4)                
                _http_port=80
                _https_port=443
                _host=$_C
                ## used in the second part on redirects
                _http_mark='http'                                                                                
                _https_mark='https'

                

                if [ -f $SRV/$_C/pound-host ]
                then
                        _host=$(cat $SRV/$_C/pound-host)
                fi        

                ## custom directive for the backend port
                if [ -f $SRV/$_C/pound-http-port ]
                then
                        _http_port=$(cat $SRV/$_C/pound-http-port)
                fi

                if [ -f $SRV/$_C/pound-https-port ]
                then
                        _https_port=$(cat $SRV/$_C/pound-https-port)
                fi

                if [ ! -f $SRV/$_C/disabed ]
                then

                        ## Direct Developer DomainName - useful if your domain is not registered / dns has problems
                        if $ENABLE_DDDN
                        then
                                set_file $cfg_dir/dddn-http-service '## srvctl dddn-http-service '$_C' '$_ip' 
                                Service
                                          HeadRequire "Host: '$_C'.'$DDN'"
                                          BackEnd
                                              Address '$_C'
                                              Port    '$_http_port'
                                              '"$(cat -s $SRV/$_C/pound-http-service-directives 2> /dev/null)"'
                                          End
                                End'
 
                                set_file $cfg_dir/dddn-https-service '## srvctl dddn-https-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$_C'.'$DDN'"
                                          BackEnd
                                              Address '$_C'
                                              Port    '$_https_port'
                                              '"$(cat -s $SRV/$_C/pound-https-service-directives 2> /dev/null)"'
                                              HTTPS
                                          End
                                End'

                                echo 'Include "'$cfg_dir/dddn-http-service'"' >> /var/pound/http-dddn-domains.cfg
                                echo 'Include "'$cfg_dir/dddn-https-service'"' >> /var/pound/https-dddn-domains.cfg
                        fi 


                        ## Directly addressed alternative pound domain on custom port
                        if [ -f $SRV/$_C/pound-enable-altdomain ]
                        then
                                altdomain_hostname=$_C'.'$DDN                        
                                if [ ! -z $(cat $SRV/$_C/pound-enable-altdomain) ]
                                then
                                        altdomain_hostname=$(cat $SRV/$_C/pound-enable-altdomain)
                                fi

                                altdomain_http_port=8080
                                if [ -f $SRV/$_C/pound-altdomain-http-port ]
                                then
                                        altdomain_http_port=$(cat $SRV/$_C/pound-http-port)
                                fi

                                altdomain_https_port=8443
                                if [ -f $SRV/$_C/pound-altdomain-https-port ]
                                then
                                        altdomain_https_port=$(cat $SRV/$_C/pound-https-port)
                                fi

                                set_file $cfg_dir/altdomain-http-service '## srvctl altdomain-http-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$altdomain_hostname'"
                                          BackEnd
                                              Address '$_C'
                                              Port    '$altdomain_http_port'
                                              '"$(cat -s $SRV/$_C/pound-altdomain-http-service-directives 2> /dev/null)"'
                                          End
                                End'
 
                                set_file $cfg_dir/altdomain-https-service '## srvctl altdomain-https-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$altdomain_hostname'"
                                          BackEnd
                                              Address '$_C'
                                              Port    '$altdomain_https_port'
                                              '"$(cat -s $SRV/$_C/pound-altdomain-https-service-directives 2> /dev/null)"'
                                              HTTPS
                                          End
                                End'

                                echo 'Include "'$cfg_dir/altdomain-http-service'"' >> /var/pound/http-domains.cfg
                                echo 'Include "'$cfg_dir/altdomain-https-service'"' >> /var/pound/https-domains.cfg
                        fi
                        

                        if [ -f $SRV/$_C/pound-enable-dev ]
                        then
                                set_file $cfg_dir/dev-http-service '## srvctl dev-http-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: dev.'$_C'"
                                          Redirect "https://dev.'$_C'"
                                End'
 
                                set_file $cfg_dir/dev-https-service '## srvctl dev-https-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: dev.'$_C'"
                                          BackEnd
                                              Address '$_C'
                                              Port    9001
                                              TimeOut 300
                                          End
                                End'

                                echo 'Include "'$cfg_dir/dev-http-service'"' >> /var/pound/http-domains.cfg
                                echo 'Include "'$cfg_dir/dev-https-service'"' >> /var/pound/https-domains.cfg
                        fi

                        if [ -f $SRV/$_C/pound-enable-log ] || [ -f $SRV/$_C/pound-enable-dev ]
                        then
                                ## log.io currently broken on https. https://github.com/NarrativeScience/Log.io/issues/124
                                
                                set_file $cfg_dir/log-http-service '## srvctl log-http-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: log.'$_C'"
                                          #Redirect "https://log.'$_C'"
                                          BackEnd
                                              Address '$_C'
                                              Port    9003
                                              TimeOut 300
                                          End
                                End'
 
                                ## for now, redirect to http
                                set_file $cfg_dir/log-https-service '## srvctl log-https-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: log.'$_C'"
                                          Redirect "http://log.'$_C'"

                                End'

                                echo 'Include "'$cfg_dir/log-http-service'"' >> /var/pound/http-domains.cfg
                                echo 'Include "'$cfg_dir/log-https-service'"' >> /var/pound/https-domains.cfg
                        fi
                                ### TODO ### Add posibility for custom arguments for pound
                        if [ -f $SRV/$_C/pound-no-http ]
                        then
                                set_file $cfg_dir/http-service '## srvctl http-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$_host'"
                                          Redirect "https://'$_host'"
                                End'

                                _http_mark='https'
                        else
                                set_file $cfg_dir/http-service '## srvctl http-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$_host'"
                                          BackEnd
                                              Address '$_C'
                                              Port    '$_http_port'
                                              '"$(cat -s $SRV/$_C/pound-http-service-directives 2> /dev/null)"'
                                          End
                                End'
                        fi

                        if [ -f $SRV/$_C/pound-no-https ]
                        then

                                set_file $cfg_dir/https-service '## srvctl https-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$_host'"
                                          Redirect "http://'$_host'"
                                End'

                                _https_mark='http'
                        else
                                set_file $cfg_dir/https-service '## srvctl https-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$_host'"
                                          BackEnd
                                              Address '$_C'
                                              Port    '$_https_port'
                                              '"$(cat -s $SRV/$_C/pound-https-service-directives 2> /dev/null)"'
                                              HTTPS
                                          End
                                End'
                        fi

                        if [ -f $SRV/$_C/pound-redirect ] && [ ! -z $(cat $SRV/$_C/pound-redirect) ]
                        then
        
                                set_file $cfg_dir/redirect-service '## srvctl redirect-service '$_C' '$_ip'
                                Service
                                          HeadRequire "Host: '$_name'"
                                          Redirect "'$(cat $SRV/$_C/pound-redirect)'"
                                End'

                                echo 'Include "'$cfg_dir/redirect-service'"' >> /var/pound/http-domains.cfg
                                echo 'Include "'$cfg_dir/redirect-service'"' >> /var/pound/https-domains.cfg
                        else

                                ## finally inlcude the demanded service
                                echo 'Include "'$cfg_dir/http-service'"' >> /var/pound/http-domains.cfg
                                echo 'Include "'$cfg_dir/https-service'"' >> /var/pound/https-domains.cfg

                        fi
                        
                        ## aliased, or match based domains - redirect only

                        for A in $(echo $_C && cat $SRV/$_C/aliases 2> /dev/null)
                        do
                                ## dnl will count the dots in the domain - for priorizing domains with more dots
                                dnl=$(echo $A | grep -o "\." | grep -c "\.")


                                if [ -f $SRV/$_C/pound-redirect ] && [ ! -z $(cat $SRV/$_C/pound-redirect) ]
                                then
        
                                        set_file $cfg_dir/$A-redirect-service '## srvctl '$A'-redirect-service '$_C' '$_ip'
                                        Service
                                                  HeadRequire "Host: .*'$A'.*"
                                                  Redirect "'$(cat $SRV/$_C/pound-redirect)'"
                                        End'
                                        ## finally inlcude the demanded service
                                        echo 'Include "'$cfg_dir/$A-redirect-service'"' >> /var/pound/http-$dnl-domains.cfg
                                        echo 'Include "'$cfg_dir/$A-redirect-service'"' >> /var/pound/https-$dnl-domains.cfg

                                else


                                        set_file $cfg_dir/$A-http-service '## srvctl '$A'-http-service '$_C' '$_ip'
                                        Service
                                                  HeadRequire "Host: .*'$A'.*"
                                                  Redirect "'$_http_mark'://'$_host'"
                                        End'

                                        set_file $cfg_dir/$A-https-service '## srvctl '$A'-https-service '$_C' '$_ip'
                                        Service
                                                  HeadRequire "Host: .*'$A'.*"
                                                  Redirect "'$_https_mark'://'$_host'"
                                        End'

                                        echo 'Include "'$cfg_dir/$A-http-service'"' >> /var/pound/http-$dnl-domains.cfg
                                        echo 'Include "'$cfg_dir/$A-https-service'"' >> /var/pound/https-$dnl-domains.cfg


                                fi

                        done ## for Container and all aliases
                fi

                ## if there is some problem, start an automatic debug process, that skips broken configs
                if [ "$1" == "debug" ]
                then
                        
                        systemctl restart pound.service
                        test=$(systemctl is-active pound.service)

                        if [ "$test" == "active" ]
                        then
                                msg "$_C pound OK"
                                
                                ## Ok, make a backup of this state.
                                cat /var/pound/http-includes.cfg > /var/pound/http-includes.lok
                                cat /var/pound/https-includes.cfg > /var/pound/https-includes.lok
                                cat /var/pound/https-certificates.cfg > /var/pound/https-certificates.lok

                                cat /var/pound/http-domains.cfg > /var/pound/http-domains.lok
                                cat /var/pound/http-dddn-domains.cfg > /var/pound/http-dddn-domains.lok

                                cat /var/pound/http-8-domains.cfg > /var/pound/http-8-domains.lok
                                cat /var/pound/http-7-domains.cfg > /var/pound/http-7-domains.lok
                                cat /var/pound/http-6-domains.cfg > /var/pound/http-6-domains.lok
                                cat /var/pound/http-5-domains.cfg > /var/pound/http-5-domains.lok
                                cat /var/pound/http-4-domains.cfg > /var/pound/http-4-domains.lok
                                cat /var/pound/http-3-domains.cfg > /var/pound/http-3-domains.lok
                                cat /var/pound/http-2-domains.cfg > /var/pound/http-2-domains.lok
                                cat /var/pound/http-1-domains.cfg > /var/pound/http-1-domains.lok

                                cat /var/pound/https-domains.cfg > /var/pound/https-domains.lok
                                cat /var/pound/https-dddn-domains.cfg > /var/pound/https-dddn-domains.lok

                                cat /var/pound/https-8-domains.cfg > /var/pound/https-8-domains.lok
                                cat /var/pound/https-7-domains.cfg > /var/pound/https-7-domains.lok
                                cat /var/pound/https-6-domains.cfg > /var/pound/https-6-domains.lok
                                cat /var/pound/https-5-domains.cfg > /var/pound/https-5-domains.lok
                                cat /var/pound/https-4-domains.cfg > /var/pound/https-4-domains.lok
                                cat /var/pound/https-3-domains.cfg > /var/pound/https-3-domains.lok
                                cat /var/pound/https-2-domains.cfg > /var/pound/https-2-domains.lok
                                cat /var/pound/https-1-domains.cfg > /var/pound/https-1-domains.lok


                        else
                                ## Error in this config, skip it, .. restore the good ones.

                                cat /var/pound/http-includes.lok > /var/pound/http-includes.cfg
                                cat /var/pound/https-includes.lok > /var/pound/https-includes.cfg
                                cat /var/pound/https-certificates.lok > /var/pound/https-certificates.cfg

                                cat /var/pound/http-domains.lok > /var/pound/http-domains.cfg
                                cat /var/pound/http-dddn-domains.lok > /var/pound/http-dddn-domains.cfg
                                
                                cat /var/pound/http-8-domains.lok > /var/pound/http-8-domains.cfg
                                cat /var/pound/http-7-domains.lok > /var/pound/http-7-domains.cfg
                                cat /var/pound/http-6-domains.lok > /var/pound/http-6-domains.cfg
                                cat /var/pound/http-5-domains.lok > /var/pound/http-5-domains.cfg
                                cat /var/pound/http-4-domains.lok > /var/pound/http-4-domains.cfg
                                cat /var/pound/http-3-domains.lok > /var/pound/http-3-domains.cfg
                                cat /var/pound/http-2-domains.lok > /var/pound/http-2-domains.cfg
                                cat /var/pound/http-1-domains.lok > /var/pound/http-1-domains.cfg

                                cat /var/pound/https-domains.lok > /var/pound/https-domains.cfg
                                cat /var/pound/https-dddn-domains.lok > /var/pound/https-dddn-domains.cfg

                                cat /var/pound/https-8-domains.lok > /var/pound/https-8-domains.cfg
                                cat /var/pound/https-7-domains.lok > /var/pound/https-7-domains.cfg
                                cat /var/pound/https-6-domains.lok > /var/pound/https-6-domains.cfg
                                cat /var/pound/https-5-domains.lok > /var/pound/https-5-domains.cfg
                                cat /var/pound/https-4-domains.lok > /var/pound/https-4-domains.cfg
                                cat /var/pound/https-3-domains.lok > /var/pound/https-3-domains.cfg
                                cat /var/pound/https-2-domains.lok > /var/pound/https-2-domains.cfg
                                cat /var/pound/https-1-domains.lok > /var/pound/https-1-domains.cfg
                                
                                log "$_C Pound restart FAILED!"
                                systemctl status pound.service

                                echo '--------- DEBUG ----------'
                                cd /var/pound/$_C 
                                cat *
                                echo '--------------------------'
                        fi
                        ## if no sleep,.. pound.service start request repeated too quickly, refusing to start.
                        sleep 3
                fi
                


        done ## foreach container

        systemctl restart pound.service

        test=$(systemctl is-active pound.service)

        if [ "$test" == "active" ]
        then
                msg "Restarted pound.service."
        else
                ## pound syntax check
                pound -c -f /etc/pound.cfg

                err "Pound restart FAILED!"
                systemctl status pound.service

                msg "Debbuging pound configuration..."
                regenerate_pound_files debug
        fi

}

function regenerate_root_configs {

#echo "Checking root's .ssh configs"

### User checks
        ## for root
        if [ ! -f /root/.ssh/id_rsa.pub ]
        then
          err "ERROR - NO KEYPAIR FOR ROOT!"
        fi

        if [ ! -f /root/.ssh/authorized_keys ]
        then
          msg "WARNING - NO authorized_keys FOR ROOT!"
          #echo '' >> /root/.ssh/authorized_keys
        fi

}

function regenerate_users {
        ## First of all, make sure all users we have defined for sites, are all present.
        msg "regenarating user-list"
        for _C in $(lxc-ls)
        do
                touch $SRV/$_C/users

                for _U in $(cat $SRV/$_C/users)
                do                
                        # echo "User: $U at $C"
                
                        ## if the user doesent exists ... well, create it.
                        add_user $_U
                done
        done
}

function generate_user_configs {
        
        # echo "Generating user configs for $U"

        ## create keypair
        if [ ! -f /home/$U/.ssh/id_rsa.pub ]
        then
          msg "Creating keypair for user "$U
          create_keypair
        fi

        ## create known_hosts

        ## TODO should users have their own_hosts file?
        cat /root/.ssh/srvctl_hosts > /home/$U/.ssh/known_hosts
        chown $U:$U /home/$U/.ssh/known_hosts

        mkdir -p /root/srvctl-users/authorized_keys
        ## create user submitted authorised_keys
        if [ ! -f /home/$U/.ssh/authorized_keys ] || $all_arg_set
        then
                #log "Creating authorized_keys for $U"  
                cat /root/.ssh/authorized_keys > /home/$U/.ssh/authorized_keys
                echo '' >> /home/$U/.ssh/authorized_keys
                if [ -f  /root/srvctl-users/authorized_keys/$U ]
                then
                        cat /root/srvctl-users/authorized_keys/$U >> /home/$U/.ssh/authorized_keys
                else
                        ntc "No authorized ssh-rsa key in /root/srvctl-users/authorized_keys/$U"
                fi                
                chown $U:$U /home/$U/.ssh/authorized_keys
        fi
}


function regenerate_users_configs {

        msg "regenrateing user configs"

        for U in $(ls /home)
        do
                generate_user_configs
        done 
}

function generate_user_structure ## for user $U, Container $C
{
        # echo  "Generating user structure for $U in $C"

                ## add users host public key to container root user - for ssh access.
                if [ -f /home/$U/.ssh/id_rsa.pub ]
                then
                        cat /home/$U/.ssh/id_rsa.pub >> $SRV/$C/rootfs/root/.ssh/authorized_keys
                else
                        err "No id_rsa.pub for user "$U
                fi

                ## add users submitted public key to container root user - for ssh access.
                if [ -f /root/srvctl-users/authorized_keys/$U ]
                then
                        cat /root/srvctl-users/authorized_keys/$U >> $SRV/$C/rootfs/root/.ssh/authorized_keys
                
                        ## else
                        ## ntc "No public key for user "$U
                fi

                ## Share via mount
                ## Second, create common share
                mkdir -p /home/$U/$C/mnt
                chown $U:$U /home/$U/$C
                chown $U:$U /home/$U/$C/mnt

                ## make sure all the hashes are up to date
                # update_password $U

                ## take care of password hashes
                if ! [ -f "/home/$U/$C/.password.sha512" ]
                then
                        update_password_hash $U

                        if [ ! -f /home/$U/$C/mnt/.password.sha512 ] && [ -f /home/$U/.password ]
                        then
                                ln /home/$U/.password.sha512 /home/$U/$C/mnt/.password.sha512
                        fi
                fi

                ## create directory we will bind to
                mkdir -p $SRV/$C/rootfs/mnt/$U

                ## everything prepared, this is for container mount point.
                echo "/home/$U/$C/mnt $SRV/$C/rootfs/mnt/$U none rw,bind 0 0" >> $SRV/$C/fstab

                
}

                ## NOTE on port forwarding and ssh usage. This will allow direct ssh on a custom local port! 
                ## Create the tunnel
                ## ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -L 2222:nameof.container.ve:22 -N -f user@host
                ## connect to the tunnel
                ## ssh -p 2222 user@localhost

                ## List Open tunnels
                ##  ps ax | grep "ssh " | grep " -L "

                ## ssh with compresion
                ## ssh -C -c blowfish

                ## kill all L tunnels
                ## kill $(ps ax | grep "ssh " | grep " -L " | cut -f 1 -d " ")


function regenerate_users_structure {

        msg "Updateing user-structure."
        
        for C in $(lxc-ls)
        do

                if [ ! -z $(cat $SRV/$C/rootfs/etc/ssh/sshd_config | grep "PasswordAuthentication yes") ]
                then
                        msg "Disabling password authentication on $C"

                        ## make sure password authentication is disabled
                        sed_file $SRV/$C/rootfs/etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
                        ssh $C "systemctl restart sshd.service"

                fi
                
                cat /root/.ssh/id_rsa.pub > $SRV/$C/rootfs/root/.ssh/authorized_keys
                #echo '' >> $SRV/$C/rootfs/root/.ssh/authorized_keys
                cat /root/.ssh/authorized_keys >> $SRV/$C/rootfs/root/.ssh/authorized_keys 2> /dev/null
                chmod 600 $SRV/$C/rootfs/root/.ssh/authorized_keys
                
                ## this is there since srvctl 1.x
                echo "/var/srvctl $SRV/$C/rootfs/var/srvctl none ro,bind 0 0" > $SRV/$C/fstab
                ## in srvctl 2.x we add the folowwing
                echo "$install_dir $SRV/$C/rootfs/$install_dir none ro,bind 0 0" >> $SRV/$C/fstab
 
        
                for U in $(cat $SRV/$C/users)
                do
                        generate_user_structure
                done

                if $all_arg_set
                then

                        nfs_unmount

                        generate_exports $C
                fi                

                for U in $(cat $SRV/$C/users)
                do
                        nfs_mount
                done
         done

        ## generate host's-user's access keysets. 
        for U in $(ls /home)
        do
                ## users should be accessible by root with ssh
                cat /root/.ssh/authorized_keys > /home/$U/.ssh/authorized_keys 2> /dev/null

                ## if the user submitted a public key, add it as well.
                if [ -f /root/srvctl-users/authorized_keys/$U ]
                then
                        cat /root/srvctl-users/authorized_keys/$U >> /home/$U/.ssh/authorized_keys
                fi
        done

        ## TODO check why ...
        systemctl restart firewalld.service

}


function regenerate_dns {
        
        msg "Regenerate DNS - named/bind configs"

        rm -rf /var/named/srvctl/*

        named_conf_local=$TMP/named.conf.local
         named_slave_conf_global=$TMP/named.slave.conf.global.$(hostname)

        echo '## srvctl named.conf.local' > $named_conf_local
        echo '## srvctl named.slave.conf.global.'$(hostname) > $named_slave_conf_global

        for C in $(lxc-ls)
        do
                create_named_zone $C
                echo 'include "/var/named/srvctl/'$C'.conf";' >> $named_conf_local
                echo 'include "/var/named/srvctl/'$C'.slave.conf";' >> $named_slave_conf_global

                if [ -f /$SRV/$C/aliases ]
                then
                        for A in $(cat /$SRV/$C/aliases)
                        do
                                #msg "$A is an alias of $C"
                                create_named_zone $A
                                echo 'include "/var/named/srvctl/'$A'.conf";' >> $named_conf_local
                                echo 'include "/var/named/srvctl/'$A'.slave.conf";' >> $named_slave_conf_global
                        
                        done
                fi

        done

        bak /etc/srvctl/named.conf.local
        bak /etc/srvctl/named.slave.conf.global.$(hostname)

        rsync -a $named_conf_local /etc/srvctl
        rsync -a $named_slave_conf_global /etc/srvctl

        ## update this variable as it was synced to its real location
        named_slave_conf_global=/etc/srvctl/named.slave.conf.global.$(hostname)

        systemctl restart named.service


        test=$(systemctl is-active named.service)

        if [ "$test" == "active" ]
        then
                msg "Creating DNS share."

                ## to make sure everything is correct we regenerate the dns share too
                rm $dns_share
                tar -czPf $dns_share $named_slave_conf_global /var/named/srvctl

        else
                err "DNS Error."
                systemctl status named.service
        fi

}

function regenerate_logfiles {

        msg "Linking log files for fail2ban."        

        rm -rf /var/log/httpd
        mkdir -p /var/log/httpd

        for _C in $(lxc-ls)
        do
                if [ -f $SRV/$_C/rootfs/var/log/httpd/access_log ]
                then
                        ln -s $SRV/$_C/rootfs/var/log/httpd/access_log /var/log/httpd/$_C-access_log
                fi
                if [ -f $SRV/$_C/rootfs/var/log/httpd/error_log ]
                then
                        ln -s $SRV/$_C/rootfs/var/log/httpd/error_log /var/log/httpd/$_C-error_log
                fi
        done

        ## TODO fix /check fail2ban
        #systemctl restart fail2ban.service
        

}

function regenerate_counter {

__c=0
        for _C in $(lxc-ls)
        do
                __n=$(cat $SRV/$_C/config.counter)

                if [ "$__n" -gt "$__c" ]
                then
                        __c=$__n
                fi
        done
        
        counter=$(cat /etc/srvctl/counter)
        if ! [ "$counter" -eq "$__c" ]
        then
                msg "Counter: $counter vs $__c"
                ## todo, .. should the counter set __c ?
        fi
        
}


## constants for generate_lxc_config
## we do some expansion on the IP address, and extract the network prefix.
if [ "$RANGEv6" != "::1" ] 
then
    IPv6_RANGE=$(sipcalc -6 $RANGEv6 2>/dev/null | fgrep Expanded | cut -d '-' -f 2 | xargs)
    IPv6_RANGE_NETBLOCK=$(echo $IPv6_RANGE | cut -d : -f 1):$(echo $IPv6_RANGE | cut -d : -f 2):$(echo $IPv6_RANGE | cut -d : -f 3):$(echo $IPv6_RANGE | cut -d : -f 4)
fi

function generate_lxc_config {

## argument container name.
_c=$1

ntc "Generating lxc configarion files for $_c"

_counter=$(cat $SRV/$_c/config.counter)

_mac=$(to_mac $_counter)
_ip4=$(to_ip $_counter)        

## four digit hex part only
_ip6=$(to_ipv6 $_counter)

if [ "$RANGEv6" != "::1" ] 
then

    __IPv6_1='lxc.network.ipv6.gateway=auto'
    __IPv6_2='lxc.network.ipv6='$IPv6_RANGE_NETBLOCK':0:1010:'$_ip6':1'
fi

## note currently working only with range 64 ip addresses.

#lxc.network.type = veth
#lxc.network.flags = up
#lxc.network.link = inet-br
#lxc.network.hwaddr = 00:00:00:aa:'$_mac'
#lxc.network.ipv4 = 192.168.'$_ip4'/8
#lxc.network.name = inet-'$_counter'

set_file $SRV/$_c/config '## Template for srvctl created fedora container #'$_counter' '$_c' '$NOW'

## system
lxc.rootfs = '$SRV'/'$_c'/rootfs
lxc.include = '$lxc_usr_path'/share/lxc/config/fedora.common.conf
lxc.utsname = '$_c'
lxc.autodev = 1

## extra mountpoints
lxc.mount = '$SRV'/'$_c'/fstab

## networking IPv4
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = srv-net
lxc.network.hwaddr = 00:00:10:10:'$_mac'
lxc.network.ipv4 = 10.10.'$_ip4'/8
lxc.network.name = srv-'$_counter'
lxc.network.ipv4.gateway = auto
'

## IPv6
## four digit hex part only
_ip6=$(to_ipv6 $_counter)

if [ "$RANGEv6" != "::1" ] 
then
    echo '## networking IPv6' >> $SRV/$_c/config
    echo 'lxc.network.ipv6.gateway = auto' >> $SRV/$_c/config
    echo 'lxc.network.ipv6='$IPv6_RANGE_NETBLOCK':0:1010:'$_ip6':1' >> $SRV/$_c/config
fi



## this is there since srvctl 1.x
echo "/var/srvctl $SRV/$_c/rootfs/var/srvctl none ro,bind 0 0" > $SRV/$_c/fstab
## in srvctl 2.x we add the folowwing
echo "$install_dir $SRV/$_c/rootfs/$install_dir none ro,bind 0 0" >> $SRV/$_c/fstab


set_file $SRV/$_c/rootfs/etc/resolv.conf "# Generated by srvctl
search local
nameserver 10.10.0.1
"

## err $C? .. $_c !
echo "10.10."$_ip4 > $SRV/$_c/config.ipv4

}

function set_file_limits {

    ## You can increase the amount of open files and thus the amount of client connections by using "ulimit -n ". 
    ## For example, to allow pound to accept 5,000 connections and forward 5,000 connection to back end servers (10,000 total) use "ulimit -n 10000".
    ulimit -n 100000

    ## Hint from Tamás Papp to fix Error: Too many open files
    sysctl fs.inotify.max_user_watches=81920 >> /dev/null
    sysctl fs.inotify.max_user_instances=1024 >> /dev/null
}

function create_named_zone {

        ## argument domain ($C or alias)
        D=$1

        mkdir -p /var/named/srvctl
        chown -R named:named /var/named/srvctl

        named_conf=/var/named/srvctl/$D.conf
        named_slave_conf=/var/named/srvctl/$D.slave.conf
        named_zone=/var/named/srvctl/$D.zone

        if [ ! -f $named_conf ]
        then
## TODO convert to single string and command, this is ugly.
                echo '## srvctl named.conf '$D > $named_conf
                echo 'zone "'$D'" {' >> $named_conf
                echo '        type master;'  >> $named_conf
                echo '        file "'$named_zone'";' >> $named_conf
                echo '};' >> $named_conf
        fi

        if [ ! -f $named_slave_conf ]
        then
                echo '## srvctl named.slave.conf '$D > $named_slave_conf
                echo 'zone "'$D'" {' >> $named_slave_conf
                echo '        type slave;'  >> $named_slave_conf
                echo '        masters {'$HOSTIPv4';};'  >> $named_slave_conf
                echo '        file "'$named_zone'";' >> $named_slave_conf
                echo '};' >> $named_slave_conf
        fi

        if [ ! -f $named_zone ]
        then
                

                serial_file=/var/named/serial-counter.txt

                if [ ! -f $serial_file ]
                then
                  serial='1'        
                  echo $serial > $serial_file
                else        
                  serial=$(($(cat $serial_file)+1))
                  echo $serial >  $serial_file
                fi

                set_file $named_zone '$TTL 1D
@        IN SOA        @ hostmaster.'$CDN'. (
                                        '$serial'        ; serial
                                        1D        ; refresh
                                        1H        ; retry
                                        1W        ; expire
                                        3H )        ; minimum
        IN         NS        ns1.'$CDN'.
        IN         NS        ns2.'$CDN'.
*        IN         A        '$HOSTIPv4'
@        IN         A        '$HOSTIPv4'
@        IN        MX        10        mail
        AAAA        ::1'

## TODO add IPv6 support

        fi

        chown named:named $named_conf
        chown named:named $named_slave_conf
        chown named:named $named_zone

        ## TODO create a nice file structure and re-enable this.
        #if [ ! -L $SRV/$C/$D.named.conf ]
        #then
        #   ln -s $named_conf $SRV/$C/$D.named.conf
        #fi

        #if [ ! -L $SRV/$C/$D.named.zone ]
        #then
        #   ln -s $named_zone $SRV/$C/$D.named.zone
        #fi
}

function wait_for_ve_online {

        ## wait for the container to get up check via keyscan
        __llimit=300        
        __n=0

        echo -n '..'

        while [  $__n -lt $__llimit ] 
        do
                sleep 1
                res=$(ssh-keyscan -t rsa -H $1 2> /dev/null)

                if [ "${res:0:3}" == '|1|' ]
                then
                        __n=$__llimit 
                else
                        echo -n '.'
                fi

                 let __n=__n+1 

        done

        echo -n " online "
}


function wait_for_ve_connection {

        ## wait for the container to get up check via ssh connect
        __llimit=300
        __n=0

        echo -n '..'

        while [  $__n -lt $__llimit ] 
        do
                sleep 1
                res=$(ssh $1 exit 2> /dev/null)

                if [ ! "$?" -gt 0 ]
                then
                        __n=$__llimit
                else
                        echo -n '.'
                fi

                 let __n=__n+1 

        done


        echo -n " connected "
}


fi ## if onHS
