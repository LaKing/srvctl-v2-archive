function regenerate_sudo_configs {
 
    sudoconf=/etc/sudoers.d/srvctl
    echo "## srvctl-regenerated sudo file" > $sudoconf
    echo '' >> $sudoconf
    if false
    then
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add-fedora *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add-ubuntu *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add-apache *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh exec *" >> $sudoconf   
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh exec-all *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh ssh-all *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh exec-all-backup-db" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh kill *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh kill-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh reboot *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh reboot-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh remove *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh start *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh start-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh stop *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh stop-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh disable *" >> $sudoconf
    
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh list" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh ls" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh status" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh status-all" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh usage" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh import-crt *" >> $sudoconf    
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh import-ca *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add-user *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh add-publickey *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh show-csr *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh top" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh scan" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh phpscan" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh clamscan" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh backup" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh backup *" >> $sudoconf
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh restore *" >> $sudoconf
    fi
    ## this will allow users to run: sc container command
    echo "ALL ALL=(ALL) NOPASSWD: $install_dir/srvctl-sudo.sh *" >> $sudoconf
    ## makes all other sudo entries above unnecessery
    
    
}

