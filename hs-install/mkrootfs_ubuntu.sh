
function mkrootfs_ubuntu { ## N name
 
    ## this is my own version for rootfs creation
     
    local N=$1
    local SRVCTL_PKG_LIST="$2"
    local INSTALL_ROOT=/var/srvctl-rootfs/$N
    
    rm -rf $TMP/$N
    
    ## since we are on fedora, we will propably need debootstrap
    dnf -y install debootstrap
    ln -s /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/xenial 2> /dev/null
    rm -fr $INSTALL_ROOT
    ##mkdir -p $INSTALL_ROOT
    
    export DEBIAN_FRONTEND=noninteractive
    lxc-create --dir=$INSTALL_ROOT -P $TMP  -n ubuntu -t ubuntu -- -r xenial --packages "$(echo $SRVCTL_PKG_LIST | tr ' ' ',')"
    echo 'LANG="en_US.UTF-8"' >> $INSTALL_ROOT/root/.bashrc
    echo 'LC_ALL="en_US.UTF-8"' >> $INSTALL_ROOT/root/.bashrc
    
    exif 

    msg "$N rootfs done"
}

