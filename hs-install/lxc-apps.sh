## @update-install
if [ ! -d /var/srvctl-host/apps ] || $all_arg_set
then

    msg "Installing srvctl apps"
        ## this is done already at end of the lxc-template, however, .. we should make sure.
        #rm -rf /usr/local/var/cache/lxc/fedora
        #rm -rf /var/cache/lxc/fedora
    
    ## we reinstall anyway    
    rm -rf /var/srvctl-host/apps 

    mkdir -p /var/srvctl-host/apps 
    source $install_dir/hs-install/apps/*

fi


