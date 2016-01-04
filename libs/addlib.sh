function setup_rootfs_ssh { ## needs rootfs

        ## make root's key access
        mkdir -m 600 $rootfs/root/.ssh
        cat /root/.ssh/id_rsa.pub > $rootfs/root/.ssh/authorized_keys
        cat /root/.ssh/authorized_keys >> $rootfs/root/.ssh/authorized_keys
        chmod 600 $rootfs/root/.ssh/authorized_keys
        
        ## disable password authentication on ssh
        sed_file $rootfs/etc/ssh/sshd_config "PasswordAuthentication yes" "PasswordAuthentication no"
}

function setup_srvctl_ve_dirs { ## needs rootfs

        ## srvctl 2.x installation dir
        mkdir -p $rootfs/var/srvctl
        mkdir -p $rootfs/etc/srvctl
        mkdir -p $rootfs/$install_dir
        rm -rf $rootfs/var/cache/dnf/*

        ## add symlink to the srvctl application.
        ln -sf $install_dir/srvctl.sh $rootfs/bin/srvctl
        ln -sf $install_dir/srvctl.sh $rootfs/bin/sc

}

function setup_index_html { ## needs rootfs and some name as argument
    
        ## set default index page 
        index=$rootfs/var/www/html/index.html
        echo '<head></head><body bgcolor="#333"><div id="header" style="background-color:#151515;">
        <img src="logo.png" alt="'"$CMP"'" style="display: block; margin-left: auto; margin-right: auto; vertical-align: middle"></div>
        <p align="center"><font color="#aaa" style="margin-left: auto; margin-right: auto" size="6px" face="Arial">' > $index
        echo '<b>'$1'</b> @ '$HOSTNAME >> $index
        echo '</font><p></body>' >> $index
        
        cp /var/www/html/logo.png $rootfs/var/www/html
        cp /var/www/html/favicon.ico $rootfs/var/www/html
    
    }

