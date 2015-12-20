function install_nodejs_latest {
 
 if [ "$(/usr/bin/node --version)" == "v5.2.0" ]
 then
      msg "node.js has the latest version"
 else
      msg "install latest node and npm via nodsource"
 
     dnf -y remove nodejs
     dnf -y remove npm
 
 
     ##curl --silent --location https://rpm.nodesource.com/setup | bash -  
     ## doesent work.
 
     dnf -y install https://rpm.nodesource.com/pub_5.x/fc/23/x86_64/nodejs-5.2.0-1nodesource.fc23.x86_64.rpm
     
     
  echo "node --version"
  node --version

fi

}

