if false
then

function pound_add_service__redirect {
    
    echo $_service_comment >> $_service__cfg
    echo 'Service' >> $_service__cfg
    echo $_service_head >> $_service__cfg
    echo 'Redirect "https://dev.'$_C'"' >> $_service__cfg
    echo 'End' >> $_service__cfg
}

function pound_add_service__config {
    
    echo $_service_comment >> $_service__cfg
    echo 'Service' >> $_service__cfg
    echo $_service_head >> $_service__cfg
    
    echo 'BackEnd' >> $_service__cfg
    ## backend parameters
    echo 'Address '$_C >> $_service__cfg
    echo 'Port '$_service_port >> $_service__cfg
        
    if [ $_service_name == dev ] || [ $_service_name == codepad ]
    then
        echo 'TimeOut 300' >> $_service__cfg
    fi
        
        
    if [ -f $_service_path/pound-$_service_name-http-service-directives ]
    then
        cat -s $_service_path/pound-$_service_name-http-service-directives >> $_service__cfg
    fi
    echo 'End' >> $_service__cfg
    ## backend ended
    echo 'End' >> $_service__cfg
}

function pound_add_service {

    _service_name=$1
    _service_port=443
    _service_path=$SRV/$_C/settings/
    _service_domain=$_C
    _service_doname=$(echo $_C | tr '.' '-')
    
    _service_http_cfg=$cfg_dir/$_service-http-service
    _service_https_cfg=$cfg_dir/$_service-https-service
    _service_http_only=false
    _service_https_only=false
    
    if [[ $_service_domain == *".$DDN" ]]
    then
        ## remove DDN at the end
        _service_doname=$(echo $_C | tr '.' '-')
    fi
    
    #if [ -f $SRV/$_C/settings/pound-enable-dev ]
    
    _service_comment='## srvctl '$_service' '$_C' ('$_ip')'
    _service_head='HeadRequire "Host: dev.'$_C'"'

    ## work on the http block
    _service__cfg=$_service_http_cfg
    if $_service_http_only
    then
        pound_add_service__redirect
    else
        pound_add_service__config
    fi

    ## work on the https block
    _service__cfg=$_service_https_cfg
    if $_service_https_only
    then
        pound_add_service__redirect
    else
        pound_add_service__config
    fi
    
    
    ## put the config files to the includes
    echo 'Include "'$_service_http_cfg'"' >> $pound_dir/http-domains.cfg
    echo 'Include "'$_service_https_cfg'"' >> $pound_dir/https-domains.cfg

    
}

fi

## under construction block end

function pound_add_includes { # S

    local S=/var/pound/$1

    if [ -f $S/http-includes.cfg ]
    then
        echo 'Include "'$S'/http-includes.cfg"' >> /var/pound/http-includes.cfg
    fi
    
    if [ -f $S/https-includes.cfg ]
    then
        echo 'Include "'$S'/https-includes.cfg"' >> /var/pound/https-includes.cfg
    fi
    
    if [ -f $S/https-certificates.cfg ]
    then
        echo 'Include "'$S'/https-certificates.cfg"' >> /var/pound/https-certificates.cfg   
    fi
    
    if [ -f $S/http-wildcard.cfg ]
    then
        echo 'Include "'$S'/http-wildcard.cfg"' >> /var/pound/http-wildcard.cfg
    fi
    
    if [ -f $S/https-wildcard.cfg ]
    then
        echo 'Include "'$S'/https-wildcard.cfg"' >> /var/pound/https-wildcard.cfg
    fi
}


function regenerate_pound_sync {
    
    msg "sync certificates across servers"
    
    ## The /etc/srvctl/cert folder should be maintained on ROOTCA_HOST
    if [ "$HOSTNAME" != "$ROOTCA_HOST" ]
    then
        #echo rsync --delete -aze ssh $ROOTCA_HOST:/etc/srvctl/cert /etc/srvctl/cert
              rsync --delete -aze ssh $ROOTCA_HOST:/etc/srvctl/cert /etc/srvctl/cert
    fi
    
    local MSG="## srvctl pound main $NOW"
    echo $MSG > /var/pound/http-includes.cfg
    echo $MSG > /var/pound/https-includes.cfg
    echo $MSG > /var/pound/https-certificates.cfg
    echo $MSG > /var/pound/http-wildcard.cfg
    echo $MSG > /var/pound/https-wildcard.cfg    
    
    
    echo 'Include "/var/pound/https-certificates.cfg"' >> /var/pound/https-includes.cfg
    
    for _S in $SRVCTL_HOSTS
    do
        if [ "$(ssh -n -o ConnectTimeout=1 $_S '[ -d /var/pound/$HOSTNAME ] && hostname || echo err' 2> /dev/null)" == "$_S" ]
        then
            msg "Pound sync $_S"
            
            rsync --delete -aze ssh $_S:/var/pound/$_S /var/pound
            
        else
            err "Could not fetch pound configurations from $_S"
        fi
    done
    
    
    
    ## import host certificates
    for _d in $(ls /etc/srvctl/cert)
    do
        pound_pem=/etc/srvctl/cert/$_d/pound.pem
        if [ -f $pound_pem ]
        then
            echo 'Cert "'$pound_pem'"' >> /var/pound/https-certificates.cfg
        fi
    done
    
    pound_add_includes $HOSTNAME
    
    for _S in $SRVCTL_HOSTS
    do        
        pound_add_includes $_S 
    done

     echo 'Include "/var/pound/http-wildcard.cfg"' >> /var/pound/http-includes.cfg
     echo 'Include "/var/pound/https-wildcard.cfg"' >> /var/pound/https-includes.cfg
    
}

function regenerate_pound_files {
  
  msg "regenerate pound files"

  local pound_dir=/var/pound/$HOSTNAME
  
  rm -rf $pound_dir
  mkdir -p $pound_dir
  
  local MSG="## srvctl $HOSTNAME generated $NOW"
  
  ## We will use a sort of layering, with up to 8 layers.
  
  ## We assume that /etc/pound.cfg has two includes ...
  echo $MSG > $pound_dir/http-includes.cfg
  echo $MSG > $pound_dir/https-includes.cfg
  echo $MSG > $pound_dir/https-certificates.cfg
  
  echo $MSG > $pound_dir/http-domains.cfg
  echo $MSG > $pound_dir/http-dddn-domains.cfg
  
  echo $MSG > $pound_dir/http-wildcard.cfg
  echo $MSG > $pound_dir/https-wildcard.cfg
  
  ## the number is the count of dots.
  ## with this we try to catch misstyped domains where possible - using wildcards
  ## and redirect them ...
  
  echo $MSG > $pound_dir/http-8-domains.cfg
  echo $MSG > $pound_dir/http-7-domains.cfg
  echo $MSG > $pound_dir/http-6-domains.cfg
  echo $MSG > $pound_dir/http-5-domains.cfg
  echo $MSG > $pound_dir/http-4-domains.cfg
  echo $MSG > $pound_dir/http-3-domains.cfg
  echo $MSG > $pound_dir/http-2-domains.cfg
  echo $MSG > $pound_dir/http-1-domains.cfg
  
  echo $MSG > $pound_dir/https-domains.cfg
  echo $MSG > $pound_dir/https-dddn-domains.cfg
  
  echo $MSG > $pound_dir/https-8-domains.cfg
  echo $MSG > $pound_dir/https-7-domains.cfg
  echo $MSG > $pound_dir/https-6-domains.cfg
  echo $MSG > $pound_dir/https-5-domains.cfg
  echo $MSG > $pound_dir/https-4-domains.cfg
  echo $MSG > $pound_dir/https-3-domains.cfg
  echo $MSG > $pound_dir/https-2-domains.cfg
  echo $MSG > $pound_dir/https-1-domains.cfg
  
  #echo 'Include "'$pound_dir'/https-certificates.cfg"' >> $pound_dir/https-includes.cfg
  
  echo 'Include "'$pound_dir'/acme-server.cfg"' >> $pound_dir/http-includes.cfg
  echo 'Include "'$pound_dir'/http-domains.cfg"' >> $pound_dir/http-includes.cfg
  echo 'Include "'$pound_dir'/http-dddn-domains.cfg"' >> $pound_dir/http-includes.cfg
  
  echo 'Include "'$pound_dir'/http-8-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  echo 'Include "'$pound_dir'/http-7-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  echo 'Include "'$pound_dir'/http-6-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  echo 'Include "'$pound_dir'/http-5-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  echo 'Include "'$pound_dir'/http-4-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  echo 'Include "'$pound_dir'/http-3-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  echo 'Include "'$pound_dir'/http-2-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  echo 'Include "'$pound_dir'/http-1-domains.cfg"' >> $pound_dir/http-wildcard.cfg
  
  echo 'Include "'$pound_dir'/https-domains.cfg"' >> $pound_dir/https-includes.cfg
  echo 'Include "'$pound_dir'/https-dddn-domains.cfg"' >> $pound_dir/https-includes.cfg
  
  echo 'Include "'$pound_dir'/https-8-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  echo 'Include "'$pound_dir'/https-7-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  echo 'Include "'$pound_dir'/https-6-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  echo 'Include "'$pound_dir'/https-5-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  echo 'Include "'$pound_dir'/https-4-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  echo 'Include "'$pound_dir'/https-3-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  echo 'Include "'$pound_dir'/https-2-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  echo 'Include "'$pound_dir'/https-1-domains.cfg"' >> $pound_dir/https-wildcard.cfg
  
  ## first of all, set up the acme server
  set_file $pound_dir/acme-server.cfg '## srvctl generated letsencrypt responder
        Service
            URL "^/.well-known/acme-challenge/*"
            BackEnd
                Address localhost
                Port    1028
            End
        End
  '

  
  ## $_C is the local version of $C - the containers
  for _C in $(lxc-ls)
  do
    
    if [ ${_C:0:5} == "mail." ]
    then
      ## mail servers have no domains
      ## TODO - web client? 
      continue
    fi

    cfg_dir=$pound_dir/$_C
    mkdir -p $cfg_dir 
    
    ## import container certificates
    pound_pem=$SRV/$_C/cert/pound.pem
    if [ -f $pound_pem ]
    then
        cat $pound_pem > $cfg_dir/pound.pem
        echo 'Cert "'$cfg_dir'/pound.pem"' >> $pound_dir/https-certificates.cfg
    fi
    
    ## create configs
    _ip=$(cat $SRV/$_C/config.ipv4)
    _http_port=80
    _https_port=443
    _host=$_C
    
    ## used in the second part on redirects
    _http_mark='http'
    _https_mark='https'
    
    ## a-b-c.domain.org notation
    _DC=$(echo $_C | tr '.' '-')
    
    
    if [ -f $SRV/$_C/settings/pound-host ]
    then
      _host=$(cat $SRV/$_C/settings/pound-host)
    fi
    
    ## custom directive for the backend port
    if [ -f $SRV/$_C/settings/pound-http-port ]
    then
      _http_port=$(cat $SRV/$_C/settings/pound-http-port)
    fi
    
    if [ -f $SRV/$_C/settings/pound-https-port ]
    then
      _https_port=$(cat $SRV/$_C/settings/pound-https-port)
    fi
    
    if [ ! -f $SRV/$_C/disabed ]
    then
      
      ## Direct Developer DomainName - useful if your domain is not registered / dns has problems
      ## syntax ve-domain-name.hostname
      ## always enabled
      
      set_file $cfg_dir/dddn-http-service '## srvctl dddn-http-service '$_C' '$_ip'
      Service
      HeadRequire "Host: '$_DC'.'$SDN'"
      BackEnd
      Address '$_C'
      Port    '$_http_port'
      '"$(cat -s $SRV/$_C/settings/pound-http-service-directives 2> /dev/null)"'
      End
      End'
      
      set_file $cfg_dir/dddn-https-service '## srvctl dddn-https-service '$_C' '$_ip'
      Service
      HeadRequire "Host: '$_DC'.'$SDN'"
      BackEnd
      Address '$_C'
      Port    '$_https_port'
      '"$(cat -s $SRV/$_C/settings/pound-https-service-directives 2> /dev/null)"'
      HTTPS
      End
      End'
      
      echo 'Include "'$cfg_dir/dddn-http-service'"' >> $pound_dir/http-dddn-domains.cfg
      echo 'Include "'$cfg_dir/dddn-https-service'"' >> $pound_dir/https-dddn-domains.cfg

      
      
      ## Directly addressed alternative pound domain on custom port
      if [ -f $SRV/$_C/settings/pound-enable-altdomain ]
      then
        altdomain_hostname=$_DC'.alt.'$SDN
        if [ ! -z $(cat $SRV/$_C/settings/pound-enable-altdomain | grep '.') ]
        then
          altdomain_hostname=$(cat $SRV/$_C/settings/pound-enable-altdomain)
        fi
        
        altdomain_http_port=8080
        if [ -f $SRV/$_C/settings/pound-altdomain-http-port ]
        then
          altdomain_http_port=$(cat $SRV/$_C/settings/pound-http-port)
        fi
        
        altdomain_https_port=8443
        if [ -f $SRV/$_C/settings/pound-altdomain-https-port ]
        then
          altdomain_https_port=$(cat $SRV/$_C/settings/pound-https-port)
        fi
        
        set_file $cfg_dir/altdomain-http-service '## srvctl altdomain-http-service '$_C' '$_ip'
        Service
        HeadRequire "Host: '$altdomain_hostname'"
        BackEnd
        Address '$_C'
        Port    '$altdomain_http_port'
        '"$(cat -s $SRV/$_C/settings/pound-altdomain-http-service-directives 2> /dev/null)"'
        End
        End'
        
        set_file $cfg_dir/altdomain-https-service '## srvctl altdomain-https-service '$_C' '$_ip'
        Service
        HeadRequire "Host: '$altdomain_hostname'"
        BackEnd
        Address '$_C'
        Port    '$altdomain_https_port'
        '"$(cat -s $SRV/$_C/settings/pound-altdomain-https-service-directives 2> /dev/null)"'
        HTTPS
        End
        End'
        
        echo 'Include "'$cfg_dir/altdomain-http-service'"' >> $pound_dir/http-domains.cfg
        echo 'Include "'$cfg_dir/altdomain-https-service'"' >> $pound_dir/https-domains.cfg
      fi
      
      ## disabled - under construction
      #if [ -f $SRV/$_C/settings/pound-enable-dev ]
      #then
      #    pound_add_service dev
      #fi

      ## SDN based codepad
      if [ -f $SRV/$_C/rootfs/etc/codepad/settings.json ]
      then
        set_file $cfg_dir/codepad-http-service '## srvctl codepad-http-service '$_C' '$_ip'
        Service
            HeadRequire "Host: '$_DC'.codepad.'$SDN'"
            Redirect "https://'$_DC'.codepad.'$SDN'"
        End
        
        Service
            HeadRequire "Host: '$_DC'.dev.'$SDN'"
            Redirect "https://'$_DC'.dev.'$SDN'"
        End        
        '
        
        set_file $cfg_dir/codepad-https-service '## srvctl codepad-https-service '$_C' '$_ip'
        Service
            HeadRequire "Host: '$_DC'.codepad.'$SDN'"
            BackEnd
                Address '$_C'
                Port    9001
                TimeOut 300
            End
        End
        Service
            HeadRequire "Host: '$_DC'.dev.'$SDN'"
            BackEnd
                Address '$_C'
                Port    9001
                TimeOut 300
            End
        End      
        '
        
        echo 'Include "'$cfg_dir/codepad-http-service'"' >> $pound_dir/http-domains.cfg
        echo 'Include "'$cfg_dir/codepad-https-service'"' >> $pound_dir/https-domains.cfg
        
        set_file $cfg_dir/play-https-service '## srvctl play-https-service '$_C' '$_ip'
        Service
            HeadRequire "Host: '$_DC'.play.'$SDN'"
            BackEnd
                Address '$_C'
                Port    8443
                TimeOut 300
                HTTPS
            End
        End
        Service
            HeadRequire "Host: '$_DC'.run.'$SDN'"
            BackEnd
                Address '$_C'
                Port    8443
                TimeOut 300
                HTTPS
            End
        End        
        '
        
        set_file $cfg_dir/play-http-service '## srvctl play-http-service '$_C' '$_ip'
        Service
            HeadRequire "Host: '$_DC'.play.'$SDN'"
            BackEnd
                Address '$_C'
                Port    8080
                TimeOut 300
            End
        End
        Service
            HeadRequire "Host: '$_DC'.run.'$SDN'"
            BackEnd
                Address '$_C'
                Port    8080
                TimeOut 300
            End
        End       
        '
        
        echo 'Include "'$cfg_dir/play-http-service'"' >> $pound_dir/http-domains.cfg
        echo 'Include "'$cfg_dir/play-https-service'"' >> $pound_dir/https-domains.cfg
        
      fi
      

      ## LEGACY dev.

      if [ -f $SRV/$_C/settings/pound-enable-dev ]
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
        
        echo 'Include "'$cfg_dir/dev-http-service'"' >> $pound_dir/http-domains.cfg
        echo 'Include "'$cfg_dir/dev-https-service'"' >> $pound_dir/https-domains.cfg
      fi
      
      
      
      ## LEGACY log.
      
      if [ -f $SRV/$_C/settings/pound-enable-log ] || [ -f $SRV/$_C/settings/pound-enable-dev ]
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
        
        echo 'Include "'$cfg_dir/log-http-service'"' >> $pound_dir/http-domains.cfg
        echo 'Include "'$cfg_dir/log-https-service'"' >> $pound_dir/https-domains.cfg
      fi
      
      
    if [ "${_C: -6}" == ".devel" ] || [ "${_C: -6}" == "-devel" ] || [ "${_C: -6}" == "-local" ] || [ "${_C: -6}" == ".local" ]
    then
          echo 0 > /dev/null
    else
      
      ### TODO ### Add posibility for custom arguments for pound
      if [ -f $SRV/$_C/settings/pound-no-http ]
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
        '"$(cat -s $SRV/$_C/settings/pound-http-service-directives 2> /dev/null)"'
        End
        End'
      fi
      
      if [ -f $SRV/$_C/settings/pound-no-https ]
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
        '"$(cat -s $SRV/$_C/settings/pound-https-service-directives 2> /dev/null)"'
        HTTPS
        End
        End'
      fi
      
      if [ -f $SRV/$_C/settings/pound-redirect ] && [ ! -z $(cat $SRV/$_C/settings/pound-redirect) ]
      then
        
        set_file $cfg_dir/redirect-service '## srvctl redirect-service '$_C' '$_ip'
        Service
        HeadRequire "Host: '$_C'"
        Redirect "'$(cat $SRV/$_C/settings/pound-redirect)'"
        End'
        
        echo 'Include "'$cfg_dir/redirect-service'"' >> $pound_dir/http-domains.cfg
        echo 'Include "'$cfg_dir/redirect-service'"' >> $pound_dir/https-domains.cfg
      else
        
        ## finally inlcude the demanded service
        echo 'Include "'$cfg_dir/http-service'"' >> $pound_dir/http-domains.cfg
        echo 'Include "'$cfg_dir/https-service'"' >> $pound_dir/https-domains.cfg
        
      fi
    
    fi
      
      ## pound aliases redirect other domains here
      if [ -f $SRV/$_C/settings/pound-aliases ]
      then
        for A in $(cat $SRV/$_C/settings/pound-aliases 2> /dev/null)
        do
          if [ -d $SRV/$A ]
          then
            err "Pound configuration error in $SRV/$_C/settings/pound-aliases: $A exists as a container."
            continue
          fi
          
          set_file $cfg_dir/$A-http-alias-service '## srvctl redirect-service '$_C' '$_ip'
          Service
          HeadRequire "Host: '$A'"
          Redirect "http://'$_C'"
          End'
          
          set_file $cfg_dir/$A-https-alias-service '## srvctl redirect-service '$_C' '$_ip'
          Service
          HeadRequire "Host: '$A'"
          Redirect "https://'$_C'"
          End'
          
          echo 'Include "'$cfg_dir/$A-http-alias-service'"' >> $pound_dir/http-domains.cfg
          echo 'Include "'$cfg_dir/$A-https-alias-service'"' >> $pound_dir/https-domains.cfg
          
        done
      fi
      
      ## aliased, or match based domains - redirect only
      
      for A in $(echo $_C && cat $SRV/$_C/settings/aliases 2> /dev/null)
      do
        
        ## dnl will count the dots in the domain - for priorizing domains with more dots
        dnl=$(echo $A | grep -o "\." | grep -c "\.")
        # TODO: BUGGED!!!!
        
        if [ -f $SRV/$_C/settings/pound-redirect ] && [ ! -z $(cat $SRV/$_C/settings/pound-redirect) ]
        then
          
          set_file $cfg_dir/$A-redirect-service '## srvctl '$A'-redirect-service '$_C' '$_ip'
          Service
          HeadRequire "Host: .*'$A'.*"
          Redirect "'$(cat $SRV/$_C/settings/pound-redirect)'"
          End'
          ## finally inlcude the demanded service
          echo 'Include "'$cfg_dir/$A-redirect-service'"' >> $pound_dir/http-$dnl-domains.cfg
          echo 'Include "'$cfg_dir/$A-redirect-service'"' >> $pound_dir/https-$dnl-domains.cfg
          
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
          
          echo 'Include "'$cfg_dir/$A-http-service'"' >> $pound_dir/http-$dnl-domains.cfg
          echo 'Include "'$cfg_dir/$A-https-service'"' >> $pound_dir/https-$dnl-domains.cfg
          
          
        fi
        
      done ## for Container and all aliases
    fi
    
  done ## foreach container
    
}

function restart_pound {
   
  systemctl restart pound.service
  
  test=$(systemctl is-active pound.service)
  
  if [ "$test" == "active" ]
  then
    msg "restarted pound.service"
  else
    ## pound syntax check
    pound -c -f /etc/pound.cfg
    
    err "Pound restart FAILED!"
    systemctl status pound.service --no-pager
  fi   
}

