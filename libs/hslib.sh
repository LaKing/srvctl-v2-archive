#!/bin/bash

#### srvctl helper functions used by some host-commands

function set_is_running {
        ## argument container
        local _c=$C

        if [ ! -z "$1" ]
        then
              local _c=$1
        fi        

        local info=$(lxc-info -s -n $_c)
        local state=${info:16}
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

function say_name {
        ## container $C name
        printf ${NC}"%-48s"${NC} $1
}

function get_ip {

        ipv4=''
        ip=$(cat $SRV/$C/config.ipv4)

        if [ -z "$ip" ] 
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
    
        info="$(lxc-info -s -n $C | grep State)"

        state="${info:16}"
        is_running=false

        if [ "$state" == "RUNNING" ] && [ ! -z "$ip" ]
        then
                ping_ms=$(ping -r -I srv-net -W 1 -c 1 $ip | grep rtt) 
                msc=$green
                ms=${ping_ms:23:5}"ms"
                is_running=true
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

RESP_TEST_COMM='curl -o /dev/null -k -s -w %{time_total}'

function get_pound_state {

        ps='none'
        if [ ! -z $ip ] && [ "$(systemctl is-active pound.service)" = "active" ]
        then
          ps=$(poundctl -c /var/lib/pound/pound.cfg | grep $ip'' | tail -c 5)
          
        fi
        
        if [ "$ps" != "live" ]
        then
            printf ${red}"%-12s"${NC} ERR!
            return
        fi
        
        if ! $is_running
        then
            printf ${yellow}"%-12s"${NC} "----- ----- "    
            return
        fi
        
        http__rt=$(curl -o /dev/null -k -s -w %{time_total} http://$C)
        http__rc=$?
        https_rt=$(curl -o /dev/null -k -s -w %{time_total} https://$C)
        https_rc=$?
        
        if [ $http__rc != 0 ]
        then
            printf ${red}"%-6s"${NC} $http__rt  
        else
            printf ${green}"%-6s"${NC} $http__rt 
        fi
        
        if [ $https_rc != 0 ] 
        then
            printf ${red}"%-6s"${NC} $https_rt
        else
            printf ${green}"%-6s"${NC} $https_rt
        fi
}

function get_disk_usage {
dbg 'get_disk_usage'
dbg "du -hs $SRV/$C | head -c 4"
        du=$(du -hs $SRV/$C | head -c 4 )
dbg 'done'
        printf ${NC}"%-5s"${NC} $du
}

function get_logs_usage {

        du=$(du -hs $SRV/$C/rootfs/var/log | head -c 4 )

        printf ${NC}"%-5s"${NC} $du
}

function get_dig_A {
    
        if [ "${C: -6}" == "-devel" ] || [ "${C: -6}" == ".devel" ] || [ "${C: -6}" == ".local" ] || [ "${C: -6}" == ".local" ]
        then
            printf ${green}"%-3s"${NC} "--"
            return
        fi

        dig_A=$(dig +time=1 +short $C)        
        
        if [ -z "$dig_A" ]
        then
            printf ${red}"%-3s"${NC} "??"
            return
        fi
        
        if grep -q "$dig_A" /var/srvctl/ifcfg/ipv4
        then
                if [ "$(cat $SRV/$C/dns-provider)" == "$CDN" ]
                then
                    printf ${green}"%-3s"${NC} "OK"
                else
                    printf ${yellow}"%-3s"${NC} "ok"
                fi
        else
            printf ${red}"%-3s"${NC} " ?"
        fi


        #dig=$(nslookup $C | grep -A 3 answer | tail -n 2 | head -n 1)

        #printf ${yellow}"%-16s"${NC} ${dig_result}
}

function get_dig_MX {
        
        if [ "${C: -6}" == "-devel" ] || [ "${C: -6}" == ".devel" ] || [ "${C: -6}" == ".local" ] || [ "${C: -6}" == ".local" ]
        then
            printf ${green}"%-3s"${NC} "--"
            return
        fi
        
        if [ ${C:0:5} == "mail." ]
        then
            printf ${green}"%-3s"${NC} "--"
            return
        fi

        dig_MX=$(dig +time=1 +short $C MX | cut -d \  -f 2)
        
        if [ -z "$dig_MX" ]
        then
            printf ${red}"%-3s"${NC} "--"
            return
        fi

        if [ "$dig_MX" == "mail.$C." ]
        then
            dig_A=$(dig +time=1 +short mail.$C)     
            if [ -z "$dig_A" ]
            then
                printf ${red}"%-3s"${NC} "??"
                return
            fi
                if grep -q "$dig_A" /var/srvctl/ifcfg/ipv4
                then
                    printf ${green}"%-3s"${NC} "OK"
                else
                    printf ${yellow}"%-3s"${NC} "<>"
                fi
                
        else
                printf ${red}"%-3s"${NC} "<>"
        fi
}

function get_users {

        mkdir -p $SRV/$C/settings
        touch $SRV/$C/settings/users

        users=$(cat $SRV/$C/settings/users | sed ':a;N;$!ba;s/\n/|/g')

        printf ${yellow}"%-32s"${NC} ${users:0:32}
}


function get_ctype {
        
        local _ctype="fedora"
        if [ -f $SRV/$C/ctype ]
        then
            _ctype=$(cat $SRV/$C/ctype | xargs)
        fi

        printf ${NC}"%-10s"${NC} ${_ctype}
}

function get_details {
        
        if [ -f $SRV/$C/rootfs/etc/os-release ]
        then
            source $SRV/$C/rootfs/etc/os-release
            printf ${NC}"%-32s"${NC} "$NAME $VERSION"
        else
            printf ${red}"%-32s"${NC} "ERROR no os-release"
        fi
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






