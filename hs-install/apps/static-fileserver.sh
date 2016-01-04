msg "Installing static fileserver app as shared container."

_SC=static-fileserver.app.local

lxc-stop -n $_SC
rm -rf $SRV/$_SC

        echo lxc-create -n $_SC -t fedora-app
        

        if lxc-create -n $_SC -t fedora-app
        then
              ntc "Appcontainer $_SC created."
        else
              err "Container not created!"
              #exit 30
        fi

        
        rootfs=$SRV/$_SC/rootfs

        setup_rootfs_ssh
        setup_srvctl_ve_dirs
        setup_index_html
        
    set_file $SRV/$_SC/config '## Template for srvctl app-container

## system
lxc.rootfs = /srv/static-fileserver.app.local/rootfs
lxc.include = /usr/share/lxc/config/fedora.common.conf
lxc.utsname = static-fileserver.app.local
lxc.autodev = 1

## extra mountpoints
#lxc.mount = /srv/test.sc.d250.hu/fstab

## networking IPv4
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = srv-net
lxc.network.hwaddr = 00:00:10:10:ff:01
lxc.network.ipv4 = 10.10.251.1/8
lxc.network.name = app-1
lxc.network.ipv4.gateway = auto
'
     
    echo lxc-start -o $SRV/$_SC/lxc.log -n $_SC -d 
    if lxc-start -o $SRV/$_SC/lxc.log -n $_SC -d
    then  
        wait_for_ve_online $C
    else
        err "FAILED to set up static-fielserver app."
        exit 132
    fi
    
    lxc-attach -n static-fileserver.app.local dnf -y remove postfix dovecot sendmail mailx


