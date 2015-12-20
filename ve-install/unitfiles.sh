## print unitfiles used on the VE

systempath="/lib/systemd/system"
binarypath="/srv"

if $onHS
then
    systempath="$SRV/$C/rootfs/lib/systemd/system"
    binarypath="$SRV/$C/rootfs/srv"
fi


## standard codepad app
if ! [ -f $binarypath/codepad.sh ]
then
set_file $systempath/codepad.service '## srvctl generated
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
fi

## node project is an editable runfile
if ! [ -f $binarypath/node-project/run.sh ]
then
set_file $systempath/node-project.service '## srvctl generated
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
fi

## standard app
if ! [ -f $binarypath/logio.sh ]
then
set_file $systempath/logio.service '## srvctl generated
[Unit]
Description=Log.io, a web-browser based realtime log monitoring tool..
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/srv/logio.sh
User=srv
Group=srv

[Install]
WantedBy=multi-user.target
'
fi

systemctl daemon-reload

