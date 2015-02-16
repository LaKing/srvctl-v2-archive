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


function get_info {

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

        if [ -f $SRV/$C/disabled ]
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
                printf ${red}"%-3s"${NC} "??"
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
                printf ${red}"%-3s"${NC} "??"
        fi
}

function get_users {

        touch $SRV/$C/users

        users=$(cat $SRV/$C/users | sed ':a;N;$!ba;s/\n/|/g')

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

function generate_exports {
        ## argument container $C

        mkdir -p $SRV/$C/rootfs/var/git

        chown git:codepad $SRV/$C/rootfs/var/git
        chown apache:apache $SRV/$C/rootfs/var/www/html
        chown srv:srv $SRV/$C/rootfs/srv

        ## keep exports consistent with srvctl system_users !!

        ## We export everything with the userIDs in mind, eg: /var/www/html - with apache user rights
        set_file  $SRV/$C/rootfs/etc/exports '## srvctl generated
/var/log 10.10.0.1(ro)
/srv 10.10.0.1(rw,all_squash,anonuid=101,anongid=101)
/var/git 10.10.0.1(rw,all_squash,anonuid=102,anongid=102)
/var/www/html 10.10.0.1(rw,all_squash,anonuid=48,anongid=48)
'

}


function nfs_mount_folder {
        ## $1 container-path (folder $F) user $U on container $C

                F=$(basename $1) 

                if [ -z "$(mount | grep /home/$U/$C/$F )" ] 
                then
                        mkdir -p /home/$U/$C/$F

                        msg "NFS - mount $U $C $F"
                        mount -t nfs $C:$1 /home/$U/$C/$F

                fi
}



function nfs_mount {
        ## for user $U on container $C
                
        set_is_running
        if $is_running
        then
                ## share via NFS

                if [ ! -z "$(rpcinfo -p $C 2> /dev/null | grep nfs)" ] 
                then                        
                        while read line ## of exports file
                        do
                                if ! [ -z "$(echo $line | grep 10.10.0.1 )" ] && [ ${line:0:1} == '/' ]
                                then
                                        nfs_mount_folder $(echo $line | cut -d ' ' -f 1)
                                fi

                        done < $SRV/$C/rootfs/etc/exports

                fi 
        fi
}

function nfs_share {
        ## container $C

        if [ -f $SRV/$C/users ]
        then
                for U in $(cat $SRV/$C/users)
                do
                        nfs_mount
                done
        fi
}

function nfs_unmount {
        ## container $C
        _C=$C
                for _U in $(ls /home)
                do
                        for _F in $(ls /home/$_U/$_C 2> /dev/null)
                        do 
                                if ! [ -z "$(mount | grep /home/$_U/$_C/$_F )" ] && ! [ "$_C" == "mnt" ]
                                then
                                        msg "NFS unmount $_U $_C $_F"
                                        
                                        ## log out user from ssh
                                        pkill -u $_U

                                        ## unmount folder
                                        umount /home/$_U/$_C/$_F
                                        
                                        if [ "$?" == "0" ]
                                        then
                                                rm -rf /home/$_U/$_C/$_F
                                        else
                                                err "Unmount failed for /home/$_U/$_C/$_F"
                                        fi
                                fi 
                        done
                done
}

