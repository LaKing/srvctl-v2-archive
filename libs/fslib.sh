function bind_mount { ## container
        
    local _C=$1

        if [ -f $SRV/$_C/settings/users ]
        then
                for _U in $(cat $SRV/$_C/settings/users)
                do
                    mkdir -p /home/$_U/$_C/bind
                    chown $_U:$_U /home/$_U/$_C/bind
                    chmod 775 /home/$_U/$_C/bind
                
                    for f in /var/log /srv /var/www/html /var/git /home /opt
                    do  
                        _F=$(basename $f)
                        
                        if [ -z "$(mount | grep /home/$_U/$_C/bind/$_F )" ] && [ -d $SRV/$_C/rootfs/$f ] 
                        then
                            msg "Bindmount $_U $_C $_F"
                            mkdir -p /home/$_U/$_C/bind/$_F
                            mount --bind $SRV/$_C/rootfs/$f /home/$_U/$_C/bind/$_F
                            
                            if [ $f == /var/www/html ]
                            then
                                chown apache:apache /home/$_U/$_C/bind/$_F
                                chmod 775 /home/$_U/$_C/bind/$_F
                            fi     
                            
                            if [ $f == /srv ]
                            then
                                chown srv:srv /home/$_U/$_C/bind/$_F
                                chmod 775 /home/$_U/$_C/bind/$_F
                            fi     
                            
                            
                            if [ $f == /var/git ]
                            then
                                chown git:git /home/$_U/$_C/bind/$_F
                                chmod 775 /home/$_U/$_C/bind/$_F
                            fi     
                        fi
                    done
                    
                    
                    
                done
        fi
}

function bind_unmount {
    local _C=$1
                for _U in $(ls /home)
                do
                        for _F in $(ls /home/$_U/$_C/bind 2> /dev/null)
                        do 
                                if ! [ -z "$(mount | grep /home/$_U/$_C/bind/$_F )" ]
                                then
                                        msg "Bindunmount $_U $_C $_F"

                                        umount -f -l /home/$_U/$_C/bind/$_F
                                        
                                        if [ "$?" == "0" ]
                                        then                                                
                                                rm -rf /home/$_U/$_C/bind/$_F
                                        else
                                                err "Bind-unmount failed for /home/$_U/$_C/bind/$_F"
                                        fi
                                        
                                fi 
                        done
                done
    
}

function mnt_rorootfs {
  
    if [ -z "$(mount | grep /var/srvctl-rorootfs)" ]
    then
         msg "Bind Mounting readonly rootfs"
            
            mkdir -p  /var/srvctl-rorootfs
            
            mount --bind /var/srvctl-rootfs /var/srvctl-rorootfs
            mount -o remount,ro,bind /var/srvctl-rorootfs
    fi
}

function generate_exports { # for rootfs

        mkdir -p $1/var/git

        chown git:codepad $1/var/git
        chown apache:apache $1/var/www/html
        chown srv:srv $1/srv

        ## keep exports consistent with srvctl system_users !!

        ## We export everything with the userIDs in mind, eg: /var/www/html - with apache user rights
        set_file  $1/etc/exports '## srvctl generated
/var/log 10.10.0.1(ro)
/srv 10.10.0.1(rw,all_squash,anonuid=101,anongid=101)
/var/git 10.10.0.1(rw,all_squash,anonuid=102,anongid=102)
/var/www/html 10.10.0.1(rw,all_squash,anonuid=48,anongid=48)
'

}


#function nfs_mount_folder {
#        ## $1 container-path (folder $F) user $_u on container $_c
#
#                F=$(basename $1) 
#
#                if [ -z "$(mount | grep /home/$_u/$_c/nfs/$F )" ] 
#                then
#                        mkdir -p /home/$_u/$_c/nfs/$F
#
#                        msg "NFS - mount $_u $_c $F"
#                        mount -t nfs $_c:$1 /home/$_u/$_c/nfs/$F
#
#                fi
#}



function nfs_mount { # user on container
    
    local _C=$1

    if [ -f $SRV/$_C/settings/users ]
    then
    
        for _U in $(cat $SRV/$_C/settings/users)        
        do
         
            set_is_running $_C
            
            if $is_running
            then
                ## share via NFS IF nfs is RUNNING
                if [ ! -z "$(rpcinfo -p $_C 2> /dev/null | grep nfs)" ] 
                then                        
                        while read line ## of exports file
                        do
                                if ! [ -z "$(echo $line | grep 10.10.0.1 )" ] && [ ${line:0:1} == '/' ]
                                then
                                        #nfs_mount_folder $(echo $line | cut -d ' ' -f 1)
                                        
                                        local f=$(echo $line | cut -d ' ' -f 1)
                                        local F=$(basename $f) 

                                        if [ -z "$(mount | grep /home/$_U/$_C/nfs/$F )" ] 
                                        then
                                            mkdir -p /home/$_U/$_C/nfs/$F

                                            msg "NFS - mount $_U $_C $F"
                                            mount -t nfs $_C:$f /home/$_U/$_C/nfs/$F

                                        fi
                                        
                                fi

                        done < $SRV/$_c/rootfs/etc/exports
                        ## we could use showmount -e here ....
                fi 
            fi
        done
    fi
}


function nfs_unmount { ## container
        local _C=$1
                for _U in $(ls /home)
                do
                        for _F in $(ls /home/$_U/$_C/nfs 2> /dev/null)
                        do 
                                if ! [ -z "$(mount | grep /home/$_U/$_C/nfs/$_F )" ]
                                then
                                        msg "NFS unmount $_U $_C $_F"
                                        
                                        ## log out user from ssh
                                        #pkill -u $_U

                                        ## unmount folder
                                        umount -f -l /home/$_U/$_C/nfs/$_F
                                        
                                        if [ "$?" == "0" ]
                                        then                                                
                                                rm -rf /home/$_U/$_C/nfs/$_F
                                        else
                                                err "Unmount failed for /home/$_U/$_C/nfs/$_F"
                                        fi
                                        
                                fi 
                        done
                done
}


