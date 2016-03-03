
function mkrootfs_fedora { ## N name
 
     ## this is my own version for rootfs creation
     
     local N=$1
     local SRVCTL_PKG_LIST="$2"
     local INSTALL_ROOT=/var/srvctl-rootfs/$N
    
     if [ ! -d /var/srvctl-rootfs/$N ] || ! $all_arg_set
     then
     
     msg "Make fedora-based rootfs for $N"
     echo ".. using base package list + $SRVCTL_PKG_LIST"
     
     
     rm -rf $INSTALL_ROOT
     mkdir -p $INSTALL_ROOT
     get_password
     
     root_password="$password"
     utsname=$N.local

     ## we create local variables from the srvctl system variables to have an easy life with templates.
     release=$VERSION_ID
     basearch=$ARCH
     
     MIRRORLIST_URL="http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$release&arch=$basearch"
     BASE_PKG_LIST="dnf initscripts passwd rsyslog vim-minimal openssh-server openssh-clients dhclient chkconfig rootfiles policycoreutils fedora-repos fedora-release"
     
     #MIRROR_URLS=$(curl -s -S -f "$MIRRORLIST_URL" | sed -e '/^http:/!d' -e '2,6!d')
     #echo $MIRROR_URLS
     
    ## code block taken from fedora template
    DOWNLOAD_OK=false
     
    # We're splitting the old loop into two loops plus a directory retrival.
    # First loop...  Try and retrive a mirror list with retries and a slight
    # delay between attempts...
    for trynumber in 1 2 3 4; do
        [ $trynumber != 1 ] && echo "Trying again..."
        # This code is mildly "brittle" in that it assumes a certain
        # page format and parsing HTML.  I've done worse.  :-P
        MIRROR_URLS=$(curl -s -S -f "$MIRRORLIST_URL" | sed -e '/^http:/!d' -e '2,6!d')
        if [ $? -eq 0 ] && [ -n "$MIRROR_URLS" ]
        then
            break
        fi

        err "Failed to get a mirror on try $trynumber"
        sleep 3
     done

     # This will fall through if we didn't get any URLS above
     for MIRROR_URL in ${MIRROR_URLS}
     do
        msg "Using $MIRROR_URL"
        
        RELEASE_URL="$MIRROR_URL/Packages/f"


        ntc "Fetching release rpm name from $RELEASE_URL..."
        # This code is mildly "brittle" in that it assumes a certain directory
        # page format and parsing HTML.  I've done worse.  :-P
        RELEASE_RPM=$(curl -L -f "$RELEASE_URL" | sed -e "/fedora-release-${release}-/!d" -e 's/.*<a href=\"//' -e 's/\">.*//' )
        if [ $? -ne 0  -o "${RELEASE_RPM}" = "" ]; then
            err "Failed to identify fedora release rpm."
            continue
        fi

        ntc "Fetching fedora release rpm from ${RELEASE_URL}/${RELEASE_RPM}......"
        curl -L -f "${RELEASE_URL}/${RELEASE_RPM}" > ${INSTALL_ROOT}/${RELEASE_RPM}
        if [ $? -ne 0 ]; then
            err "Failed to download fedora release rpm ${RELEASE_RPM}."
            continue
        fi

        ntc "Fetching repos rpm name from $RELEASE_URL..."
        REPOS_RPM=$(curl -L -f "$RELEASE_URL" | sed -e "/fedora-repos-${release}-/!d" -e 's/.*<a href=\"//' -e 's/\">.*//' )
        if [ $? -ne 0  -o "${REPOS_RPM}" = "" ]; then
            err "Failed to identify fedora repos rpm."
            continue
        fi

        ntc "Fetching fedora repos rpm from ${RELEASE_URL}/${REPOS_RPM}..."
        curl -L -f "${RELEASE_URL}/${REPOS_RPM}" > ${INSTALL_ROOT}/${REPOS_RPM}
        if [ $? -ne 0 ]; then
            err "Failed to download fedora repos rpm ${RELEASE_RPM}."
            continue
        fi


        DOWNLOAD_OK=true
        break
    done

    if ! $DOWNLOAD_OK 
    then
        err "Download failed! Aborting."
        return 1
    else
        msg "Download fedora-release, fedora-repos OK."
    fi
    
    mkdir -p ${INSTALL_ROOT}/var/lib/rpm
    rpm --root ${INSTALL_ROOT} --initdb
        # The --nodeps is STUPID but F15 had a bogus dependency on RawHide?!?!
    rpm --root ${INSTALL_ROOT} --nodeps -ivh ${INSTALL_ROOT}/${RELEASE_RPM}
    rpm --root ${INSTALL_ROOT} -ivh ${INSTALL_ROOT}/${REPOS_RPM}
    dnf --installroot ${INSTALL_ROOT} -y --nogpgcheck install ${BASE_PKG_LIST} ${SRVCTL_PKG_LIST}
    
    ## srvctl addition
    ## nodjs has to be installed seperatley
    if [ ! -z "$nodejs_rpm_url" ]
    then
        msg "Install nodejs"
        dnf --installroot ${INSTALL_ROOT} -y --nogpgcheck install $nodejs_rpm_url
    fi
    
    if [ $? == 0 ] 
    then
        msg "$N rootfs created."
    else
        err "$N rootfs failed!"
    fi
    
    ## continue with customization / configuration
    
    rootfs_path=$INSTALL_ROOT
    
    # disable selinux in fedora
    mkdir -p $rootfs_path/selinux
    echo 0 > $rootfs_path/selinux/enforce
    
        # Also kill it in the /etc/selinux/config file if it's there...
    if [[ -f $rootfs_path/etc/selinux/config ]]
    then
        sed -i '/^SELINUX=/s/.*/SELINUX=disabled/' $rootfs_path/etc/selinux/config
    fi

    # Nice catch from Dwight Engen in the Oracle template.
    # Wantonly plagerized here with much appreciation.
    if [ -f $rootfs_path/usr/sbin/selinuxenabled ]; then
        mv $rootfs_path/usr/sbin/selinuxenabled $rootfs_path/usr/sbin/selinuxenabled.lxcorig
        ln -s /bin/false $rootfs_path/usr/sbin/selinuxenabled
    fi

    # This is a known problem and documented in RedHat bugzilla as relating
    # to a problem with auditing enabled.  This prevents an error in
    # the container "Cannot make/remove an entry for the specified session"
    sed -i '/^session.*pam_loginuid.so/s/^session/# session/' ${rootfs_path}/etc/pam.d/login
    sed -i '/^session.*pam_loginuid.so/s/^session/# session/' ${rootfs_path}/etc/pam.d/sshd

    if [ -f ${rootfs_path}/etc/pam.d/crond ]
    then
        sed -i '/^session.*pam_loginuid.so/s/^session/# session/' ${rootfs_path}/etc/pam.d/crond
    fi

    # In addition to disabling pam_loginuid in the above config files
    # we'll also disable it by linking it to pam_permit to catch any
    # we missed or any that get installed after the container is built.
    #
    # Catch either or both 32 and 64 bit archs.
    if [ -f ${rootfs_path}/lib/security/pam_loginuid.so ]
    then
        ( cd ${rootfs_path}/lib/security/
        mv pam_loginuid.so pam_loginuid.so.disabled
        ln -s pam_permit.so pam_loginuid.so
        )
    fi

    if [ -f ${rootfs_path}/lib64/security/pam_loginuid.so ]
    then
        ( cd ${rootfs_path}/lib64/security/
        mv pam_loginuid.so pam_loginuid.so.disabled
        ln -s pam_permit.so pam_loginuid.so
        )
    fi

    # Set default localtime to the host localtime if not set...
    if [ -e /etc/localtime -a ! -e ${rootfs_path}/etc/localtime ]
    then
        # if /etc/localtime is a symlink, this should preserve it.
        cp -a /etc/localtime ${rootfs_path}/etc/localtime
    fi
    
        # configure the network using the dhcp
    cat <<EOF > ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
HOSTNAME=${utsname}
DHCP_HOSTNAME=\`hostname\`
NM_CONTROLLED=no
TYPE=Ethernet
MTU=${MTU}
EOF

    # set the hostname
    cat <<EOF > ${rootfs_path}/etc/sysconfig/network
NETWORKING=yes
HOSTNAME=${utsname}
EOF

    # set hostname on systemd Fedora systems
    if [ $release -gt 14 ]; then
        echo "${utsname}" > ${rootfs_path}/etc/hostname
    fi

    # set minimal hosts
    cat <<EOF > $rootfs_path/etc/hosts
127.0.0.1 localhost.localdomain localhost $utsname
::1                 localhost6.localdomain6 localhost6
EOF

    # allow root login on console, tty[1-4], and pts/0 for libvirt
    echo "# LXC (Linux Containers)" >>${rootfs_path}/etc/securetty
    echo "lxc/console"  >>${rootfs_path}/etc/securetty
    echo "lxc/tty1"     >>${rootfs_path}/etc/securetty
    echo "lxc/tty2"     >>${rootfs_path}/etc/securetty
    echo "lxc/tty3"     >>${rootfs_path}/etc/securetty
    echo "lxc/tty4"     >>${rootfs_path}/etc/securetty
    echo "# For libvirt/Virtual Machine Monitor" >>${rootfs_path}/etc/securetty
    echo "pts/0"        >>${rootfs_path}/etc/securetty
    
    #echo "root:$root_password" | chroot $rootfs_path chpasswd
    
    # specifying this in the initial packages doesn't always work.
    # Even though it should have...
    echo "installing fedora-release package"
    mount -o bind /dev ${rootfs_path}/dev
    mount -t proc proc ${rootfs_path}/proc
    # Always make sure /etc/resolv.conf is up to date in the target!
    cp /etc/resolv.conf ${rootfs_path}/etc/
    # Rebuild the rpm database based on the target rpm version...
    rm -f ${rootfs_path}/var/lib/rpm/__db*
    chroot ${rootfs_path} rpm --rebuilddb
    #chroot ${rootfs_path} dnf -y install fedora-release

    if [[ ! -e ${rootfs_path}/sbin/NetworkManager ]]
    then
        # NetworkManager has not been installed.  Use the
        # legacy chkconfig command to enable the network startup
        # scripts in the container.
        chroot ${rootfs_path} chkconfig network on
    fi

    umount ${rootfs_path}/proc
    umount ${rootfs_path}/dev

    # silence some needless startup errors
    touch ${rootfs_path}/etc/fstab

    # give us a console on /dev/console
    sed -i 's/ACTIVE_CONSOLES=.*$/ACTIVE_CONSOLES="\/dev\/console \/dev\/tty[1-4]"/' \
        ${rootfs_path}/etc/sysconfig/init
        
    #msg "Configure systemd"
        
        rm -f ${rootfs_path}/etc/systemd/system/default.target
    touch ${rootfs_path}/etc/fstab
    chroot ${rootfs_path} ln -s /dev/null /etc/systemd/system/udev.service
    chroot ${rootfs_path} ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
    # Make systemd honor SIGPWR
    chroot ${rootfs_path} ln -s /usr/lib/systemd/system/halt.target /etc/systemd/system/sigpwr.target

    # if desired, prevent systemd from over-mounting /tmp with tmpfs
    #if [ $masktmp -eq 1 ]; then
    #    chroot ${rootfs_path} ln -s /dev/null /etc/systemd/system/tmp.mount
    #fi

    #dependency on a device unit fails it specially that we disabled udev
    # sed -i 's/After=dev-%i.device/After=/' ${rootfs_path}/lib/systemd/system/getty\@.service
    # ... refer to original template

    sed -e 's/^ConditionPathExists=/# ConditionPathExists=/' \
        -e 's/After=dev-%i.device/After=/' \
        < ${rootfs_path}/lib/systemd/system/getty\@.service \
        > ${rootfs_path}/etc/systemd/system/getty\@.service
    # Setup getty service on the 4 ttys we are going to allow in the
    # default config.  Number should match lxc.tty
    ( cd ${rootfs_path}/etc/systemd/system/getty.target.wants
        for i in 1 2 3 4 ; do ln -sf ../getty\@.service getty@tty${i}.service; done )
     

    msg "$N rootfs done"
    
    fi
}

