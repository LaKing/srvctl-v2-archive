function install_mongodb {
    
    msg "MongoDB - setup repository and install latest version!"
                
    dnf -y install 'dnf-command(config-manager)'

    dnf config-manager --add-repo https://repo.mongodb.org/yum/redhat/7/mongodb-org/3.0/x86_64/ 
    dnf -y update
    dnf -y install mongodb-org --nogpgcheck        

    msg "MongoDB - setup system services!"

    #Start-Up MongoDB
    systemctl enable mongod
    systemctl start mongod

    #Check MongoDB Service Status
    systemctl status mongod



}

