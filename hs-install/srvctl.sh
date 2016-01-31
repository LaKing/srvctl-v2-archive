      
if [ "$UID" -ne "0" ]
then  
    echo "Root privileges needed to run this script. Trying with sudo."  
    ## Attemt to get root privileges with sudo, and run the script  
    sudo bash $0 $USR  
    exit
fi

msg "Install/update srvctl"

if ! [ -f /usr/bin/git ]
then
    dnf -y install git
fi

#if [ -z "$install_dir" ]
#then
#    install_dir=/usr/share/srvctl
#fi

if [ ! -d "$install_dir" ]
then
    ## srvctl is not installed, or this function was called outside of srvctl
    echo "Installing to /usr/share/srvctl"
    mkdir -p /usr/share
    cd /usr/share
    git clone https://github.com/LaKing/srvctl.git
    
else
    ## we are called from srvctl
    cv="$(cat $install_dir/version)"
    gv="$(curl https://raw.githubusercontent.com/LaKing/srvctl/master/version | xargs)"
    
    if [ "$gv" != "$cv" ] 
    then
        echo "WARNING on srvctl version"
        echo "Current version is $cv"
        echo "git version is: $gv"
    fi
      
    if [ -d "$install_dir/.git" ]
    then  
        echo "Update over git"
        cd $install_dir
        git pull
        if [ "$?" != "0" ]
        then
            echo "git pull failed. Attemt to set to https config."
            bak $install_dir/.git/config
            set_file $install_dir/.git/config '
            [core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = https://github.com/LaKing/srvctl.git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
        remote = origin
        merge = refs/heads/master
'
        git pull
        
        fi
    else
        echo "Can not update over git. Update must be performed manually." 
    fi
    
fi

## make sure symlink exist
ln -s $install_dir/srvctl.sh /bin/srvctl 2> /dev/null
ln -s $install_dir/srvctl.sh /bin/sc 2> /dev/null

