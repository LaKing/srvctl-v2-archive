function install_nodejs_latest {
 
 msg "install latest node and npm via nodsource"
 
 dnf -y remove nodejs
 dnf -y remove npm
 
 curl --silent --location https://rpm.nodesource.com/setup | bash -  
    
}

