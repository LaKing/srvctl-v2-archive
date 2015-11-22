#!/bin/bash

if $onVE && $isROOT
then ## no identation.


hint "setup-logio" "Install log.io, a web-browser based realtime log monitoring tool."
if [ "$CMD" == "setup-logio" ]
then
                ## install packages
                pm nodejs
                pm npm

                cd /srv

                npm coffee-script
                npm log.io

                mkdir -p /srv/.log.io

                conf="/srv/.log.io/harvester.conf"

                set_file $conf 'exports.config = {
  nodeName: "application_server",
  server: {
    host: "0.0.0.0",
    port: 28777
  },
  logStreams: {'


if [ -d /var/log/codepad ]
then
        echo 'codepad: [' >> $conf
        echo '  "/var/log/codepad/log",' >> $conf
        echo '  "/var/log/codepad/err"' >> $conf
        echo '],' >> $conf

        chown -R codepad:srv /var/log/codepad
        chmod -R 664 /var/log/codepad
        chmod  774 /var/log/codepad

fi


if [ -d /var/log/node-project ]
then
        echo 'project: [' >> $conf
        echo '  "/var/log/node-project/log",' >> $conf
        echo '  "/var/log/node-project/err"' >> $conf
        echo '],' >> $conf

        chown -R node:srv /var/log/node-project
        chmod -R 774 /var/log/node-project
        chmod 774 /var/log/node-project
fi

if true ## apache has logs
then

echo 'apache: [' >> $conf
echo '  "/var/log/httpd/access_log",' >> $conf
echo '  "/var/log/httpd/error_log",' >> $conf
echo '  "/var/log/httpd/ssl_access_log",' >> $conf
echo '  "/var/log/httpd/ssl_error_log",' >> $conf
echo '  "/var/log/httpd/ssl_request_log"' >> $conf
echo ']' >> $conf

        chown -R root:srv /var/log/httpd
        chmod -R 664 /var/log/httpd
        chmod 774 /var/log/httpd

fi


## TODO add other log sources here. maillog, .. etc.

echo '  }' >> $conf
echo '}' >> $conf

cat $conf > /root/.log.io/harvester.conf

get_password

conf="/srv/.log.io/web_server.conf"


set_file $conf 'exports.config = {
  host: "0.0.0.0",
  port: 9003,
 
  // Enable HTTP Basic Authentication
  auth: {
    user: "admin",
    pass: "'$password'"
  },
}
'

cat $conf > /root/.log.io/web_server.conf

conf="/srv/.log.io/log_server.conf"

set_file $conf 'exports.config = {
  host: "0.0.0.0",
  port: 28777
}
'

cat $conf > /root/.log.io/log_server.conf


                chown -R root:srv /srv/.log.io
                chmod -R 660 /srv/.log.io
                chmod 760 /srv/.log.io

                mkdir -p /var/log/logio
                chown -R root:srv /var/log/logio
                chmod -R 770 /var/log/logio
                rm -rf  /var/log/logio/*

set_file /srv/logio.sh '#!/bin/bash
echo $USER" starting "$0 

mkdir -p /var/log/logio
chown -R root:srv /var/log/logio
chmod -R 770 /var/log/logio
rm -rf  /var/log/logio/*

whoami > /var/log/logio/who


/bin/node /srv/node_modules/log.io/bin/log.io-server & 2> /var/log/logio/server-err 1> /var/log/logio/server-log
/bin/node /srv/node_modules/log.io/bin/log.io-harvester 2> /var/log/logio/harvester-err 1> /var/log/logio/harvester-log
'

chmod 770 /srv/logio.sh
chown root:srv /srv/logio.sh

source $install_dir/ve-install/unitfiles.sh

        systemctl enable logio.service
        systemctl start logio.service
        systemctl status logio.service

## TODO: increase font size to 20
## TODO restart után nem indul

        msg "Log.io: https://log.$C admin:$password"

ok
fi



fi

man '
    Install, and set up log.io to access logs from a browser.
    It should be reached on the log. subdomain with http - this however needs to enabled on the host. (pound-enable-log)
    Homepage: http://logio.org/
'


