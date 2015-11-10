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
        printf ${yellow}"%-5s"${NC} $ps

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
                printf ${yellow}"%-3s"${NC} "OK"
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





