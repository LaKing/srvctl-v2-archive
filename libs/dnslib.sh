
function get_dns_authority { ## for domain name $_c
    dns_authority=''
    ## we will buffer the dns authority
    
    if [ ! -f $SRV/$_c/dns-authority ] || $all_arg_set
    then
        _query=''
        _query="$(dig @8.8.8.8 +noall +authority  +time=1 NS $_c | cut -f1 )"
    
        if [ -z "$_query" ]
        then
            dns_authority=$_c
        else
            dns_authority="${_query%?}"
        fi
        
        ## result
        echo "$dns_authority" > $SRV/$_c/dns-authority

    fi

    ## return
    dns_authority=$(cat $SRV/$_c/dns-authority)
}

function get_dns_provider { ## for domain name $_c
    
    dns_provider=''
    if [ ! -f $SRV/$_c/dns-provider ] || $all_arg_set
    then

        ## we will buffer the dns authority
        if [ ! -f $SRV/$_c/dns-servers ] || $all_arg_set
        then
            dig @8.8.8.8 +short +answer +time=1 NS $dns_authority > $SRV/$_c/dns-servers
        fi
    
        if [ -z "$(cat $SRV/$_c/dns-servers)" ]
        then
            err "Domain $_c has no name servers. ($dns_authority?)"
        fi 
    
    
        dns_provider=''
        while read dns_server
        do 
            _query="$(dig @8.8.8.8 +noall +authority +time=1 NS $dns_server | cut -f1 )"
            if [ -z "$dns_provider" ]
            then
                dns_provider="${_query%?}"
            else
                if [ "$dns_provider" != "${_query%?}" ]
                then
                    echo "$_c has multiple DNS authorities! ($dns_provider. $_query)" > $SRV/$_c/err.log
                fi
            fi
        done < $SRV/$_c/dns-servers
    
        echo $dns_provider > $SRV/$_c/dns-provider
    else 
        dns_provider="$(cat $SRV/$_c/dns-provider)"
    fi
}

function get_dns_servers { ## argument domain
    
    _c=$1

    if [[ $_c != *.local ]]
    then
        get_dns_authority
        
        if [[ "$dns_authority" != *.* ]]
        then
            rm -rf $SRV/$_c/dns-authority
            get_dns_authority
            echo "$_c has no DNS authority. ($dns_authority?) $(cat $SRV/$_c/dns-provider 2> /dev/null)" > $SRV/$_c/err.log
        else
            get_dns_provider
        fi
    fi
}

