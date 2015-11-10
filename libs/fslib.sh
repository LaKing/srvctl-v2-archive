
function generate_exports { # container
        _C=$1

        mkdir -p $SRV/$_C/rootfs/var/git

        chown git:codepad $SRV/$_C/rootfs/var/git
        chown apache:apache $SRV/$_C/rootfs/var/www/html
        chown srv:srv $SRV/$_C/rootfs/srv

        ## keep exports consistent with srvctl system_users !!

        ## We export everything with the userIDs in mind, eg: /var/www/html - with apache user rights
        set_file  $SRV/$_C/rootfs/etc/exports '## srvctl generated
/var/log 10.10.0.1(ro)
/srv 10.10.0.1(rw,all_squash,anonuid=101,anongid=101)
/var/git 10.10.0.1(rw,all_squash,anonuid=102,anongid=102)
/var/www/html 10.10.0.1(rw,all_squash,anonuid=48,anongid=48)
'

}


function nfs_mount_folder {
        ## $1 container-path (folder $F) user $_u on container $_c

                F=$(basename $1) 

                if [ -z "$(mount | grep /home/$_u/$_c/$F )" ] 
                then
                        mkdir -p /home/$_u/$_c/$F

                        msg "NFS - mount $_u $_c $F"
                        mount -t nfs $_c:$1 /home/$_u/$_c/$F

                fi
}



function nfs_mount { # user on container
        _u=$1
        _c=$2
            
        set_is_running $_c
        if $is_running
        then
                ## share via NFS

                if [ ! -z "$(rpcinfo -p $_c 2> /dev/null | grep nfs)" ] 
                then                        
                        while read line ## of exports file
                        do
                                if ! [ -z "$(echo $line | grep 10.10.0.1 )" ] && [ ${line:0:1} == '/' ]
                                then
                                        nfs_mount_folder $(echo $line | cut -d ' ' -f 1)
                                fi

                        done < $SRV/$_c/rootfs/etc/exports

                fi 
        fi
}

function nfs_share { ## container
        _C=$1

        if [ -f $SRV/$_C/settings/users ]
        then
                for _U in $(cat $SRV/$_C/settings/users)
                do
                        nfs_mount $_U $_C
                done
        fi
}

function nfs_unmount { ## container
        _C=$1
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

