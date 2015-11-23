#!/bin/bash

#### srvctl helper functions used by some host-commands

function set_is_running {
        ## argument container
        _c=$C

        if [ ! -z "$1" ]
        then
                _c=$1
        fi        


        info=$(lxc-info -s -n $_c)
        state=${info:16}
        if [ "$state" == "RUNNING" ]
        then
          is_running=true
        else
          is_running=false
        fi
}

function say_info {
    printf ${yellow}"%-10s"${NC} $1
}

function get_info {
        ## container $C name
        printf ${NC}"%-48s"${NC} $C
}

function get_ip {

        ipv4=''
        ip=$(cat $SRV/$C/config.ipv4)

        if [ -z $ip ] 
        then
                ipv4=$(grep "lxc.network.ipv4" $SRV/$C/config)
                ip=${ipv4:19:-2}
                echo $ip > $SRV/$C/config.ipv4
        fi

        printf ${NC}"%-14s"${NC} $ip

}

function get_state {

        ms='STOPPED'

        pcs=''
        msc=${red}        

        ip=$(cat $SRV/$C/config.ipv4)

        info=$(lxc-info -s -n $C)
        state=${info:16}

        if [ "$state" == "RUNNING" ] && [ ! -z "$ip" ]
        then
                ping_ms=$(ping -r -I srv-net -W 1 -c 1 $ip | grep rtt) 
                msc=$green
                ms=${ping_ms:23:5}"ms"
        else
                ms=$state
        fi

        if [ -f $SRV/$C/settings/disabled ]
        then
                ms='-------'
                msc=$green
        fi 
        
        printf ${msc}"%-10s"${NC} $ms


}

function get_pound_state {

        ps='none'
        if [ ! -z $ip ] && [ "$(systemctl is-active pound.service)" = "active" ]
        then
          ps=$(poundctl -c /var/lib/pound/pound.cfg | grep $ip'' | tail -c 5)
          
        fi
        msc=$yellow
        printf ${msc}"%-5s"${NC} $ps

}

function get_disk_usage {

        du=$(du -hs $SRV/$C | head -c 4 )

        printf ${yellow}"%-5s"${NC} $du
}

function get_logs_usage {

        du=$(du -hs $SRV/$C/rootfs/var/log | head -c 4 )

        printf ${yellow}"%-5s"${NC} $du
}

function get_dig_A {

        dig_A=$(dig +time=1 +short $C)        

        if [ "$dig_A" == "$HOSTIPv4" ]
        then
                if [ "$SRV/$C/dns-provider" == "$CDN" ]
                then
                    printf ${green}"%-3s"${NC} "OK"
                else
                    printf ${yellow}"%-3s"${NC} "~k"
                fi
        else
                if [ -z "$dig_A" ]
                then
                    printf ${red}"%-3s"${NC} " ?"
                else
                    printf ${red}"%-3s"${NC} "!?"
                fi
        fi


        #dig=$(nslookup $C | grep -A 3 answer | tail -n 2 | head -n 1)

        #printf ${yellow}"%-16s"${NC} ${dig_result}
}

function get_dig_MX {

        dig_MX=$(dig +time=1 +short $(dig +time=1 +short $C MX | cut -d \  -f 2))
        

        if [ "$dig_MX" == "$HOSTIPv4" ]
        then
                printf ${yellow}"%-3s"${NC} "OK"
        else
                if [ -z "$dig_MX" ]
                then
                    printf ${red}"%-3s"${NC} " ?"
                else
                    printf ${red}"%-3s"${NC} "!?"
                fi
        fi
}

function get_dns_authority { ## for domain name $C
    dns_authority=''
    ## we will buffer the dns authority
    
    if [ ! -f $SRV/$C/dns-authority ] || $all_arg_set
    then
        _query=''
        _query="$(dig @8.8.8.8 +noall +authority  +time=1 NS $C | cut -f1 )"
    
        if [ -z "$_query" ]
        then
            dns_authority=$C
        else
            dns_authority="${_query%?}"
        fi
        
        ## result
        echo "$dns_authority" > $SRV/$C/dns-authority

    fi

    ## return
    dns_authority=$(cat $SRV/$C/dns-authority)
}

function get_dns_provider { ## for domain name $C
    
    dns_provider=''
    if [ ! -f $SRV/$C/dns-provider ] || $all_arg_set
    then

        ## we will buffer the dns authority
        if [ ! -f $SRV/$C/dns-servers ] || $all_arg_set
        then
            dig @8.8.8.8 +short +answer +time=1 NS $dns_authority > $SRV/$C/dns-servers
        fi
    
        if [ -z "$(cat $SRV/$C/dns-servers)" ]
        then
            err "Domain $C has no name servers. ($dns_authority?)"
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
                    echo "$C has multiple DNS authorities! ($dns_provider. $_query)" > $SRV/$C/err.log
                fi
            fi
        done < $SRV/$C/dns-servers
    
        echo $dns_provider > $SRV/$C/dns-provider
    else 
        dns_provider="$(cat $SRV/$C/dns-provider)"
    fi
}

function get_dns_servers { ## for domain $C

    if [[ $C != *.local ]]
    then
        get_dns_authority
        
        if [[ "$dns_authority" != *.* ]]
        then
            rm -rf $SRV/$C/dns-authority
            get_dns_authority
            echo "$C has no DNS authority. ($dns_authority?) $(cat $SRV/$C/dns-provider 2> /dev/null)?" > $SRV/$C/err.log
        else
            get_dns_provider
        fi
    fi
}

function get_users {

        touch $SRV/$C/settings/users

        users=$(cat $SRV/$C/settings/users | sed ':a;N;$!ba;s/\n/|/g')

        printf ${yellow}"%-32s"${NC} ${users:0:32}
}

function get_http_response {
    
    resp="---"
    resp_color=$red
    
        set_is_running
        if $is_running
        then
                            
                ## TODO better check's.
                #indexpage_curl=$(curl -s $C)
                #indexpage_tag=$(echo $indexpage_curl | grep "<title>")
                #indexpage_title=$(curl -s $C | grep "<title>")

                curli=$(curl -s -I http://$C | head -n 1)
                resp=${curli:9:3}        
                        
                if [ "$resp" == "200" ]
                then 
                  resp_color=$green
                fi
        fi
        
        printf ${resp_color}"%-4s"${NC} "$resp"
}





