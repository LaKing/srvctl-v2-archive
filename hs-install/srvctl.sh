      
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

if [ -z "$$install_dir" ]
then
    ## srvctl is not installed, or thes function was called outside of srvctl

else
    ## we are called from srvctl
    cv="$(cat $install_dir/version)"
    gv=""
fi

