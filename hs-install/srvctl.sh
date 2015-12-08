      
if [ "$UID" -ne "0" ]
then  
    echo "Root privileges needed to run this script. Trying with sudo."  
    ## Attemt to get root privileges with sudo, and run the script  
    sudo bash $0 $USR  
    exit
fi


if [ -z "$(type -a git | grep 'git is ')" ]
then
    dnf -y install git
fi

if [ -z "$install_dir" ]
then
    install_dir=/usr/share/srvctl
fi

if [ ! -d "$install_dir" ]
then
    ## srvctl is not installed, or thes function was called outside of srvctl
    echo "Installing to /usr/share/srvctl"
    mkdir -p /usr/share
    git clone git clone https://github.com/LaKing/srvctl.git
    
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
    else
        echo "Can not update over git. Update must be performed manually." 
    fi
    
fi

## make sure symlink exist
ln -s $install_dir/srvctl.sh /bin/srvctl 2> /dev/null
ln -s $install_dir/srvctl.sh /bin/sc 2> /dev/null
