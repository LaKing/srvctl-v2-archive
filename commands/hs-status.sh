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
        get_info

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
        printf ${yellow}"%-5s"${NC} "HTTP"
        printf ${yellow}"%-4s"${NC} "RES"
        printf ${yellow}"%-3s"${NC} "MX"        
        printf ${yellow}"%-5s"${NC} "DISK"
        printf ${yellow}"%-32s"${NC} "USERs"

        echo ''
    
    for C in $(lxc_ls)
    do

        get_state
        get_info
        get_ip
        get_dig_A
        get_pound_state
        get_http_response
        get_dig_MX
        get_disk_usage
        get_users

        echo ''
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

## report status of all details
hint "status-usage [username]" "Container usage status report."
if [ "$CMD" == "status-usage" ] 
then

    sudomize

    echo ''
    printf ${yellow}"%-48s"${NC} "HOSTNAME"
    printf ${yellow}"%-5s"${NC} "DISK"
    printf ${yellow}"%-5s"${NC} "LOGS"

    echo ''

    if [ ! -z "$2" ] && [ -d "/home/$2" ]
    then
        for C in $(lxc-ls)
        do      
            if ! [ -z "$(head -n 1 $SRV/$C/users | grep $2)" ]
            then
                get_info
                get_disk_usage
                get_logs_usage
                echo ''
            fi
        done
    else   

        for U in $(ls /home)
        do
            echo ''
            echo "--- $U ---"
            echo ''
            for C in $(lxc-ls)
            do       
                if ! [ -z "$(head -n 1 $SRV/$C/users | grep $U)" ]
                then
                    get_info
                    get_disk_usage
                    get_logs_usage
                    echo ''
                fi
            done
        done
    fi
 
echo ''
ok        
fi


fi ## of onHS

man '
    Usage status of containers.
        HOSTNAME - the container name.
        DISK - summarizes total diskspace usage by the container.
        LOGs - Log size gives a good approximation for network traffic.  
'
