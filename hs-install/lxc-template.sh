        ## We do some customisations in our template
        ## template path is different depending on installation, yum or some src

        

        ## ndf / yum-based install
        fedora_template="$lxc_usr_path/share/lxc/templates/lxc-fedora"
        srvctl_template="$lxc_usr_path/share/lxc/templates/lxc-fedora-srv"


## @update-install
if [ ! -f $srvctl_template ] || $all_arg_set
then
        msg "Create Custom template: $srvctl_template"

        set_file $srvctl_template '#!/bin/bash

        ## You may want to add your own sillyables, or faorite characters and customy security measures.
        declare -a pwarra=("B" "C" "D" "F" "G" "H" "J" "K" "L" "M" "N" "P" "R" "S" "T" "V" "Z")
        pwla=${#pwarra[@]}

        declare -a pwarrb=("a" "e" "i" "o" "u")
        pwlb=${#pwarrb[@]}        

        declare -a pwarrc=("" "." ":" "@" ".." "::" "@@")
        pwlc=${#pwarrc[@]}

        p=''
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        # p=$p${pwarrc[$(( RANDOM % $pwlc ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}
        p=$p${pwarra[$(( RANDOM % $pwla ))]}
        p=$p${pwarrb[$(( RANDOM % $pwlb ))]}

        root_password=$p

'
        chmod 755 $srvctl_template

        cat $fedora_template >> $srvctl_template
        ## cosmetical TODO remove second #!/bin/bash

        ## disable the root password redefining force
        sed_file $srvctl_template 'chroot $rootfs_path passwd -e root' 'echo "" ## srvctl-disabled: chroot $rootfs_path passwd -e root'
        sed_file $srvctl_template 'Container rootfs and config have been created.' 'Container rootfs and config have been created."'
        ## and do not display the dialog for that subject
        sed_file $srvctl_template 'Edit the config file to check/enable networking setup.' 'exit 0'

        ## Add additional default packages 
        sed_file $srvctl_template '    PKG_LIST="yum initscripts passwd rsyslog vim-minimal openssh-server openssh-clients dhclient chkconfig rootfiles policycoreutils fedora-release"' '    PKG_LIST="yum initscripts passwd rsyslog vim-minimal openssh-server openssh-clients dhclient chkconfig rootfiles policycoreutils fedora-release fedora-repos mc httpd mod_ssl openssl postfix mailx sendmail unzip clucene-core make  rsync nfs-utils"'

        ## fedora-repos added for fixing: https://bugzilla.redhat.com/show_bug.cgi?id=1176634

        ## wordpress mariadb mariadb-server postfix mailx sendmail dovecot .. 

        ## TODO Dovecot fails with
        ##  warning: %post(dovecot-1:2.2.13-1.fc20.x86_64) scriptlet failed, exit status 1
        ## Non-fatal POSTIN scriptlet failure in rpm package 1:dovecot-2.2.13-1.fc20.x86_64
        ## therefore it should be installed once the container started.

        ## httpd needs to be installed here, other wise it failes with cpio set_file_cap error.

        ## After modifocation of the last line, in a live filesystem, /usr/local/var/cache/lxc/fedora needs to be purged.
        log "Clearing yum cache for container creation."

        ## paths are different for src or yum install
        rm -rf /usr/local/var/cache/lxc/fedora
        rm -rf /var/cache/lxc/fedora
else
    msg "Template found at $srvctl_template"
fi ## if fedora_template does not exists.
