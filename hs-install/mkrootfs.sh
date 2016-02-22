## RE-Create rootfs dirs
    rm -rf /var/cache/lxc/*
    
    ## fedora based 
    source $install_dir/hs-install/mkrootfs_fedora.sh
    source $install_dir/hs-install/mkrootfs_ubuntu.sh
    source $install_dir/hs-install/make_rootfs_config.sh
    
    if [ ! -d /var/srvctl-rootfs/fedora ] || $all_arg_set
    then
        SRVCTL_PKG_LIST="mc httpd mod_ssl openssl postfix mailx sendmail unzip rsync nfs-utils dovecot wget"    
        #clucene-core make 
        mkrootfs_fedora fedora "$SRVCTL_PKG_LIST"
        make_rootfs_config fedora fedora
    fi

    if [ ! -d /var/srvctl-rootfs/apache ] || $all_arg_set
    then
        SRVCTL_PKG_LIST="mc httpd mod_ssl openssl unzip rsync nfs-utils lxc"    
        mkrootfs_fedora apache "$SRVCTL_PKG_LIST"
        make_rootfs_config fedora apache
    fi
    
    ## other distros
    
    if [ ! -d /var/srvctl-rootfs/ubuntu ] || $all_arg_set
    then
        if false
        then
        msg "Downloading Ubuntu-cloud image"
        
        rm -rf /var/srvctl-rootfs/ubuntu
        rm -rf $TMP/ubuntu-cloud.tar.gz
        wget -O $TMP/ubuntu-cloud.tar.gz https://cloud-images.ubuntu.com/releases/14.04/14.04.3/ubuntu-14.04-server-cloudimg-amd64-root.tar.gz
        msg "Extracting .."
        mkdir -p /var/srvctl-rootfs/ubuntu
        tar --directory /var/srvctl-rootfs/ubuntu -xzf $TMP/ubuntu-cloud.tar.gz
        rm -rf $TMP/ubuntu-cloud.tar.gz
        
        make_rootfs_config ubuntu ubuntu
        else
          
          SRVCTL_PKG_LIST="mc apache2 nfs-kernel-server postfix dovecot-imapd dovecot-pop3d unzip rsync wget language-pack-en"
          mkrootfs_ubuntu ubuntu "$SRVCTL_PKG_LIST"       
          make_rootfs_config ubuntu ubuntu
          
        fi     
        ## locale-gen en_US.UTF-8 
    fi
#source $install_dir/hs-install/lxc-apps.sh

