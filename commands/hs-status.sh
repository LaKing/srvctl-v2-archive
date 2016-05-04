#!/bin/bash

if $onHS
then ## no identation.

## report status
hint "status" "Report status of containers."
if [ "$CMD" == "status" ] 
then
    sudomize
    
    echo ''

    printf ${yellow}"%-10s"${NC} "RESPONSE"
    printf ${yellow}"%-48s"${NC} "HOSTNAME"
        
    echo ''

    for C in $(lxc_ls)
    do
        get_state
        say_name $C

        echo ''
    done
    
    echo ''
ok        
fi ## status

man '
    A quick query on all enabled containers.
    It will display the ping-time for each running container.
'

## report status of all details
hint "status-all" "Detailed container status report."
if [ "$CMD" == "status-all" ]
then

        sudomize

        echo "Hostname: "$(hostname)
        echo "Uptime:   "$(uptime)
        free -h | head -n 2

        echo ''
        printf ${yellow}"%-10s"${NC} "STATUS"
        printf ${yellow}"%-48s"${NC} "HOSTNAME"
        printf ${yellow}"%-14s"${NC} "IP-LOCAL"
        printf ${yellow}"%-3s"${NC} "IN"
        printf ${yellow}"%-12s"${NC} "HTTP  HTTPS "
        printf ${yellow}"%-4s"${NC} "RES"
        printf ${yellow}"%-3s"${NC} "MX"        
        printf ${yellow}"%-5s"${NC} "DISK"
        printf ${yellow}"%-32s"${NC} "USERs"

        echo ''
    
    for C in $(lxc_ls)
    do
        get_dns_servers $C
        
        get_state
        say_name $C
        get_ip
        get_dig_A
        get_pound_state
        get_http_response
        get_dig_MX
        get_disk_usage
        get_users
        
        if [ -f $SRV/$C/dns.log ]
        then
            echo ''
            while read line
            do
                err "$line"
            done < $SRV/$C/dns.log
        fi
        
        if [ -f $SRV/$C/rootfs/var/log/srvctl/letsencrypt.log ]
        then
            echo ''
            while read line
            do
                ntc "$line"
            done < $SRV/$C/rootfs/var/log/srvctl/letsencrypt.log
        fi
        echo ''
    done
    
    echo ''
    
    for d in /var/dyndns/*.auth
    do
        D=${d:12: -5}
        
        if [ -f "/var/dyndns/$D.auth" ]
        then
            auth=$(cat /var/dyndns/$D.auth)
            
            if [ "${auth:0:${#SC_USER}}" == $SC_USER ] || [ $SC_USER == root ]
            then
        
                IP=''
                if [ -f "/var/dyndns/$D.ip" ]
                then
                    IP=$(cat /var/dyndns/$D.ip)
                    if [ ${IP:0:7} == '::ffff:' ]
                    then
                        IP=${IP:7}
                    fi
                    
                    msg $D $IP
                fi
            
            fi
        fi
    done

    echo ''
ok        
fi

man '
    A detailed, thus slower query of all containers, displaying fields in the following order:
        STATUS - the ping time, or none for disabled containers.
        HOSTNAME - the container name.
        IP-LOCAL - the internal IPv4 address of the container.
        IN - nslookup check for the IN A DNS record. In case of no OK the container can be reached trough ve.host-hostname.
        HTTP - query pound status information.
        RES - http-reponse status code, when querying the container. It should be 200.
        MX - nslookup ncheck for the IN MX DNS record. in case of OK mail is intercepted and forwarded to the container.
        DISK - summarizes total diskspace usage by the container.
        USERs - list of usernames granted root access to the container.
        
'

## report status of disk usage
hint "usage" "Container usage status report."
if [ "$CMD" == "usage" ] 
then

    function print_header {

        echo ''
        printf ${yellow}"%-48s"${NC} "HOSTNAME"
        printf ${yellow}"%-5s"${NC} "DISK"
        printf ${yellow}"%-5s"${NC} "LOGS"
        echo ''
    }

    sudomize

    if $isSUDO 
    then
    
        msg "Statistiscs for container-owner $SC_USER"
        
        print_header

        for C in $(lxc_ls)
        do       
            if ! [ -z "$(head -n 1 $SRV/$C/settings/users | grep $SC_USER)" ]
            then
                say_name $C
                get_disk_usage
                get_logs_usage
                echo ''
            fi
        done  
        echo ''
        
        msg "Usage statistics for accessible containers."
    
        print_header
    
        for C in $(lxc_ls)
        do      
            if [ "$(cat $SRV/$C/settings/users | grep $SC_USER)" == "$SC_USER" ] && [ -z "$(head -n 1 $SRV/$C/settings/users | grep $SC_USER)" ]
            then
                say_name $C
                get_disk_usage
                get_logs_usage
                echo ''
            fi
        done
    else
        msg "Statistiscs for container-owners"
        print_header
        ## root called this
        for U in $(ls /home)
        do
            echo ''
            msg "$U"

            for C in $(lxc_ls)
            do       
                if [ "$(head -n 1 $SRV/$C/settings/users)" == "$U" ]
                then
                    say_name $C
                    get_disk_usage
                    get_logs_usage
                    echo ''
                fi
            done
            echo ''
        done


    fi
 
echo ''
ok        
fi

man '
    Usage status of containers.
        HOSTNAME - the container name.
        DISK - summarizes total diskspace usage by the container.
        LOGs - Log size gives a good approximation for network traffic.  
'

hint "list" "List containers and their internal IP information."
if [ "$CMD" == "list" ] 
then
        sudomize
        
        echo ''
        printf ${yellow}"%-10s"${NC} "TYPE"
        printf ${yellow}"%-48s"${NC} "HOSTNAME"
        printf ${yellow}"%-14s"${NC} "IP-LOCAL"
        printf ${yellow}"%-3s"${NC} "DETAILS"
        echo ''
        
        for C in $(lxc_ls)
        do 
            get_ctype
            say_name $C
            get_ip
            get_details
            echo ''
        done
echo ''
ok        
fi
man '
    A Quick list of accessible containers.
'

hint "ls" "List containers in ls format"
if [ "$CMD" == "ls" ] 
then
        sudomize 
        
        for C in $(lxc_ls)
        do 
            echo $C
        done
ok        
fi
man '
    A Quick list of acessible container names to be processed further in other scripts..
'
fi ## of onHS








