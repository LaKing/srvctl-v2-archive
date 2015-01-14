#!/bin/bash

if $onVE
then ## no identation.

hint "setup-codepad [apache|node]" "Install codepad and start a new project."
if [ "$CMD" == "setup-codepad" ]
then

                project_type=$2

                log_path="/var/log/codepad/log"

                ## set default project type, if not given in an argument
                if [ -z "$project_type" ]
                then
                        project_type="node"
                fi 

                msg $project_type-project

                setup_mariadb

                ## install packages
                yum -y install nodejs
                yum -y install npm
                yum -y install gzip git-core curl python openssl-devel
                yum -y install postgresql-devel
                yum -y install wget                

                npm -g install nodemon
                
                ## get the latest version

                if [ -d /srv/etherpad-lite ]
                then
                        cd /srv/etherpad-lite
                        git pull

                        npm update ep_codepad
                        npm update ep_cursortrace

                else        
                        cd /srv        
                        git clone git://github.com/ether/etherpad-lite.git
                
                        cd /srv/etherpad-lite 
                        npm install ep_codepad
                        #npm install ep_cursortrace

                        ### increase import filesize limitation
                        #sed_file /srv/etherpad-lite/src/node/db/PadManager.js '    if(text.length > 100000)' '    if(text.length > 1000000) /* srvctl customization for file import via webAPI*/'
                
                        ### The line containing:  return /^(g.[a-zA-Z0-9]{16}\$)?[^$]{1,50}$/.test(padId); .. but mysql is limited to 100 chars, so patch it.
                        #sed_file /srv/etherpad-lite/src/node/db/PadManager.js '{1,50}$/.test(padId);' '{1,100}$/.test(padId); /* srvctl customization for file import via webAPI*/'

                fi        


                project_path=/srv/$project_type-project 



                if [ "$project_type" == "apache" ]
                then
                        if ! [ -d "$project_path" ]
                        then
                                ln -s /var/www/html $project_path
                        fi
        
                        systemctl restart httpd.service
                        systemctl enable httpd.service

                        log_path="/var/log/httpd/error_log"
                fi

                if [ "$project_type" == "node" ]
                then

                        systemctl stop httpd.service
                        systemctl disable httpd.service

                        mkdir -p $project_path
                        chown srv:codepad $project_path
                        chmod 775 $project_path
                        log_path="/var/log/node-project/log"
                fi


                ## for sessionkey
                get_randomstr

                ## this will create / update the mysql database
                add_mariadb_db

                get_password
                adminpass=$password

        

                set_file /srv/etherpad-lite/settings.json '/* ep_codepad-devel settings*/
{
  "ep_codepad": { 
    "theme": "Cobalt",
    "project_path": "'$project_path'",
    "log_path": "'$log_path'",
    "play_url": "http://'$C'",
    "push_action": "cd '$project_path' && git add . && git commit -m codepad-auto && git push"
  },
  "title": "'$C'",
  "favicon": "favicon.ico",
  "ip": "0.0.0.0",
  "port" : 9001,
  "sessionKey" : "'$randomstr'",
  "dbType" : "mysql",
  "dbSettings" : {
    "user"    : "'$db_usr'",
    "host"    : "localhost",
    "password": "'$db_pwd'",
    "database": "'$db_name'"
  },
  "defaultPadText" : "// '$C'",
  "requireSession" : false,
  "editOnly" : false,
  "minify" : true,
  "maxAge" : 21600, 
  "abiword" : null,
  "requireAuthentication": true,
  "requireAuthorization": false,
  "trustProxy": false,
  "disableIPlogging": true,  
  "socketTransportProtocols" : ["xhr-polling", "jsonp-polling", "htmlfile"],
  "loglevel": "INFO",
  "logconfig" :
    { "appenders": [
        { "type": "console"}
      ]
    },
  "users": {
'
                for u in $(ls /mnt)
                do
                        if [ -f "/mnt/$u/.password.sha512" ]
                        then
                                echo '      "'$u'": {"hash": "'$(cat /mnt/$u/.password.sha512)'","is_admin": true},' >> /srv/etherpad-lite/settings.json
                        fi
                done

        echo '        "admin": {"password": "'$adminpass'","is_admin": true}' >> /srv/etherpad-lite/settings.json
        echo '  },' >> /srv/etherpad-lite/settings.json
        echo '}' >> /srv/etherpad-lite/settings.json

                ## prepare the enviroment
                cd /srv/etherpad-lite
                bin/installDeps.sh

                mkdir -p /var/log/codepad
                chown codepad:codepad /var/log/codepad
                chmod 750 /var/log/codepad

                set_file /srv/codepad.sh '#!/bin/bash
echo $(whoami)" starting "$0 

mkdir -p /var/log/codepad
chown codepad:srv /var/log/codepad
chmod 750 /var/log/codepad
rm -rf  /var/log/codepad/*

whoami > /var/log/codepad/who

cd /srv/etherpad-lite

while true
do
    echo RESTART >> /var/log/codepad/log
    /bin/node /srv/etherpad-lite/node_modules/ep_etherpad-lite/node/server.js $*  2> /var/log/codepad/err 1> /var/log/codepad/log
done
'

                chmod +x /srv/codepad.sh

                chown -R codepad:srv /srv/etherpad-lite

## // TODO: After mysql

                ## proper way is to create a service to run codepad
                set_file /lib/systemd/system/codepad.service '## srvctl generated
[Unit]
Description=Codepad, the etherpad-lite based collaborative code editor.
After=syslog.target network.target
After=mariadb.service

[Service]
Type=simple
ExecStart=/srv/codepad.sh
User=codepad
Group=codepad

[Install]
WantedBy=multi-user.target
'


                systemctl daemon-reload

                systemctl enable codepad.service
                systemctl start codepad.service


                if [ "$project_type" == "node" ]
                then

                        ## use the localhost certificate for node
                        mkdir -p /var/node
                        cat /etc/pki/tls/private/localhost.key > /var/node/key.pem 
                        cat /etc/pki/tls/certs/localhost.crt > /var/node/crt.pem
                        chown node:node /var/node

                        ## create sample js file

                        set_file /srv/node-project/server.js '/* srvctl generated hello-node sample file */

console.log("START");

/*
// CONSOLE-hello-world Sheep-counting 
function sleep(callback) {
  var now = new Date().getTime();
  while(new Date().getTime() < now + 1000) {
   // do nothing
  }
  callback();
}
 
console.log("Counting sheeps, .. ");
for(var i = 1; i < 50; i++) {
  sleep(function() {console.log(i)});
}
*/

// HTTP-hello-world
// Load the http module to create an http server.
var http = require("http");

// Configure our HTTP server to respond with Hello World to all requests.
var server = http.createServer(function (request, response) {
  response.writeHead(200, {"Content-Type": "text/plain"});
  response.end("Hello World\n");
});

// Listen on port 8000, IP defaults to 127.0.0.1
server.listen(8080);

// HTTPS-hello-world
var https = require("https");
var fs = require("fs");

var options = {
  key: fs.readFileSync("/var/node/key.pem"),
  cert: fs.readFileSync("/var/node/crt.pem")
};

https.createServer(options, function (req, res) {
  res.writeHead(200);
  res.end("Hello secure world\n");
}).listen(8443);

// Put a friendly message on the terminal
console.log("Server running at http://'$C'/ and at https://'$C'/");


console.log("END");
'
                        ## prepare logging capabilities
                        mkdir -p /var/log/node-project
                        chown node:codepad /var/log/node-project
                        chmod 750 /var/log/node-project

                        set_file /srv/node-project/run.sh '#!/bin/bash
echo $(whoami)" starting "$0 

mkdir -p /var/log/node-project
chown node:srv /var/log/node-project
chmod 750 /var/log/node-project

whoami > /var/log/node-project/who

cd /srv/node-project

nodemon /srv/node-project/server.js 1> /var/log/node-project/log 2> /var/log/node-project/err
'

                        set_file /lib/systemd/system/node-project.service '## srvctl generated
[Unit]
Description=Development node-project.
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/srv/node-project/run.sh
User=node
Group=node

# Restart=always
# SyslogIdentifier=node-project
# Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
'        
                                ## prepare data dir
                                chown -R node:codepad /srv/node-project
                                chmod -R 664 /srv/node-project
                                chmod 774 /srv/node-project
                                chmod 774 /srv/node-project/run.sh

                                ## this is needed for nodemon
                                chmod 777 /srv
                                ## // TODO nodemon needs to write to /srv 
                                systemctl daemon-reload

                                systemctl enable node-project.service
                                systemctl start node-project.service

                        fi ## if node-project

        
        ntc "Project path is: $project_path"

        ## this directory should be present, but we want to make sure.
        mkdir -p /var/git

        chown git:codepad /var/git
        cd /var/git

        git config --global user.name 'codepad'
        git config --global user.email codepad@$(hostname)
        git config --global push.default simple

        su codepad -s /bin/bash -c "git config --global user.name 'codepad'"
        su codepad -s /bin/bash -c "git config --global user.email codepad@$(hostname)"
        su codepad -s /bin/bash -c "git config --global push.default simple"

        ## init bare git repository
        if [ -z "$(ls /var/git)" ]
        then
                git init --bare
                echo $project_type-project > description
        else
                ntc "Git repo not empty."
        fi
        
        cd /srv

        git clone /var/git 2> /dev/null

        chown -R git:git /srv/git
        mv /srv/git/.git $project_path
        rm -rf /srv/git

        chown -R git:codepad /var/git
        chmod -R 775 /var/git

        cd $project_path

        git add . -A
        git commit -m Inital_commit

        git push
        
        chown -R git:codepad $project_path/.git
        chmod -R 775 $project_path/.git

        ### TODO allow node to run on port 80
        ## iptables to forward port 8000 to port 80
         #iptables -t nat -L

        yum -y install iptables-services

        iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080
        iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
        #iptables -t nat -A PREROUTING -p tcp --dport 250 -j REDIRECT --to-ports 9001

        iptables-save > /etc/sysconfig/iptables

        systemctl start iptables.service
        systemctl enable iptables.service

## shortcut to restart codepad
set_file /bin/rc '#!/bin/bash

systemctl restart codepad.service
systemctl status codepad.service
systemctl restart logio.service
systemctl status logio.service

sleep 2

cat /var/log/codepad/err
tail /var/log/codepad/log
'

chmod +x /bin/rc


        msg "Codepad: https://dev.$C/admin admin:$adminpass"        

ok
fi ## codepad


fi

man '
    Install, and set up codepad a collaborative code editor, or better said a collaborative online development environment.
    It should be reached on the dev. subdomain with https - this however needs to enabled on the host. (pound-enable-dev)
    Default is to create a node project, and a basic hello world application. 
    Homepage: http://D250.hu
'
