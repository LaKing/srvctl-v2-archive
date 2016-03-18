## RE-Create rootfs dirs
    rm -rf /var/cache/lxc/*
    
    ## fedora based 
    source $install_dir/hs-install/mkrootfs_fedora.sh
    source $install_dir/hs-install/mkrootfs_ubuntu.sh
    source $install_dir/hs-install/make_rootfs_config.sh
    nodejs_rpm_url=''
    
    if [ ! -d /var/srvctl-rootfs/fedora ] || $all_arg_set
    then
        SRVCTL_PKG_LIST="mc httpd mod_ssl openssl postfix mailx sendmail unzip rsync nfs-utils dovecot wget"    
        #clucene-core make 
        mkrootfs_fedora fedora "$SRVCTL_PKG_LIST"
        make_rootfs_config fedora fedora
    fi

    if [ ! -d /var/srvctl-rootfs/apache ] || $all_arg_set
    then
        SRVCTL_PKG_LIST="mc httpd mod_ssl openssl unzip rsync nfs-utils lxc"    
        mkrootfs_fedora apache "$SRVCTL_PKG_LIST"
        make_rootfs_config fedora apache
    fi
    
    if [ ! -d /var/srvctl-rootfs/codepad ] || $all_arg_set
    then
        install_nodejs_getver
        SRVCTL_PKG_LIST="mc httpd mod_ssl openssl postfix mailx sendmail unzip rsync nfs-utils dovecot lxc gzip git-core curl python openssl-devel postgresql-devel wget mariadb-server ShellCheck"  
        mkrootfs_fedora codepad "$SRVCTL_PKG_LIST"
        make_rootfs_config fedora codepad
        
        chroot /var/srvctl-rootfs/codepad/ groupadd -r -g 103 node
        chroot /var/srvctl-rootfs/codepad/ useradd -r -u 103 -g 103 -s /sbin/nologin -d /srv node
    
        chroot /var/srvctl-rootfs/codepad/ groupadd -r -g 104 codepad
        chroot /var/srvctl-rootfs/codepad/ useradd -r -u 104 -g 104 -s /sbin/nologin -d /srv/etherpad-lite codepad
        
        nodejs_rpm_url=''
        
        msg "Installing codepad"
        
        dir=/var/srvctl-rootfs/codepad/usr/share/etherpad-lite
        
        git clone git://github.com/ether/etherpad-lite.git $dir
        mkdir -p $dir/node_modules
        ln -s ../src $dir/node_modules/ep_etherpad-lite
        npm install --prefix $dir/node_modules/ep_etherpad-lite --loglevel warn
        
        dnf -y install gcc-c++

        git clone git://github.com/spcsser/ep_adminpads $dir/node_modules/ep_adminpads
        npm install --prefix $dir/node_modules/ep_adminpads --loglevel warn
        
        git clone git://github.com/LaKing/ep_codepad $dir/node_modules/ep_codepad
        npm install --prefix $dir/node_modules/ep_codepad --loglevel warn

        msg "Configuring codepad"

        ### increase import filesize limitation
        sed_file $dir/src/node/db/PadManager.js '    if(text.length > 100000)' '    if(text.length > 1000000) /* srvctl customization for file import via webAPI*/'
                
        ### The line containing:  return /^(g.[a-zA-Z0-9]{16}\$)?[^$]{1,50}$/.test(padId); .. but mysql is limited to 100 chars, so patch it.
        sed_file $dir/src/node/db/PadManager.js '{1,50}$/.test(padId);' '{1,100}$/.test(padId); /* srvctl customization for file import via webAPI*/'
        
        
        cp "$dir/src/static/custom/js.template" "$dir/src/static/custom/index.js"
        cp "$dir/src/static/custom/css.template" "$dir/src/static/custom/index.css"
        cp "$dir/src/static/custom/js.template" "$dir/src/static/custom/pad.js"
        cp "$dir/src/static/custom/css.template" "$dir/src/static/custom/pad.css"
        cp "$dir/src/static/custom/js.template" "$dir/src/static/custom/timeslider.js"
        cp "$dir/src/static/custom/css.template" "$dir/src/static/custom/timeslider.css"  
        
        #mkdir -p /var/srvctl-rootfs/codepad/var/log/codepad
        #1> /var/log/codepad/log 2> /var/log/codepad/err
        mkdir -p /var/srvctl-rootfs/codepad/lib/systemd/system
        set_file /var/srvctl-rootfs/codepad/lib/systemd/system/codepad.service '## srvctl generated
[Unit]
Description=Codepad, the etherpad-lite based collaborative code editor.
After=syslog.target network.target
After=mariadb.service

[Service]
Type=simple
ExecStartPre=/bin/mysql -e "CREATE DATABASE IF NOT EXISTS codepad"
WorkingDirectory=/usr/share/etherpad-lite
ExecStart=/bin/node /usr/share/etherpad-lite/node_modules/ep_etherpad-lite/node/server.js --settings /etc/codepad/settings.json
User=codepad
Group=codepad

[Install]
WantedBy=multi-user.target
'

mkdir -p /var/srvctl-rootfs/codepad/var/etherpad-lite
rm -rf /var/srvctl-rootfs/codepad/usr/share/etherpad-lite/var
ln -s /var/etherpad-lite /var/srvctl-rootfs/codepad/usr/share/etherpad-lite/var
chmod 774 /var/srvctl-rootfs/codepad/var/etherpad-lite
chown codepad:srv /var/srvctl-rootfs/codepad/var/etherpad-lite

mkdir -p /var/srvctl-rootfs/codepad/var/codepad
mkdir -p /var/srvctl-rootfs/codepad/etc/codepad
mkdir -p /var/srvctl-rootfs/codepad/srv/codepad-project
chown codepad:srv /var/srvctl-rootfs/codepad/srv/codepad-project

mkdir -p /var/srvctl-rootfs/codepad/var/lib/mysql
chown -R mysql:mysql /var/srvctl-rootfs/codepad/var/lib/mysql
mkdir -p /var/srvctl-rootfs/codepad/var/log/mysql
chown -R mysql:mysql /var/srvctl-rootfs/codepad/var/log/mysql

mkdir -p /var/srvctl-rootfs/codepad/var/codepad

ln -s /etc/codepad/settings.json $dir/settings.json
ln -s /etc/codepad/SESSIONKEY.txt $dir/SESSIONKEY.txt
ln -s /etc/codepad/SESSIONKEY.txt $dir/APIKEY.txt

echo 'done' > $dir/node_modules/ep_adminpads/.ep_initialized
echo 'done' > $dir/node_modules/ep_codepad/.ep_initialized
echo 'done' > $dir/node_modules/ep_etherpad-lite/.ep_initialized

chown -R codepad:codepad /var/srvctl-rootfs/codepad/etc/codepad

set_file /var/srvctl-rootfs/codepad/etc/codepad/settings.json '/* ep_codepad-devel settings*/
{
  "ep_codepad": { 
    "theme": "Cobalt",
    "project_path": "/srv/codepad-project",
    "log_path": "/var/log/codepad.log",
    "push_action": "/bin/bash /etc/codepad/push.sh"
  },
  "title": "codepad",
  "favicon": "favicon.ico",
  "ip": "0.0.0.0",
  "port" : 9001,
  "dbType" : "mysql",
  "dbSettings" : {
    "user"    : "root",
    "host"    : "localhost",
    "password": "",
    "database": "codepad"
  },
  "defaultPadText" : "// codepad",
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
}
'
set_file /var/srvctl-rootfs/codepad/etc/codepad/push.sh '#!/bin/bash

echo codepad-push
exit
cd /srv/codepad-project 
git add -A .
git commit -m codepad-auto
git push
'
chmod 744 /var/srvctl-rootfs/codepad/etc/codepad/push.sh


mkdir -p /var/srvctl-rootfs/codepad/etc/systemd/system/multi-user.target.wants/
ln -s '/usr/lib/systemd/system/postfix.service' '/var/srvctl-rootfs/codepad/etc/systemd/system/multi-user.target.wants/postfix.service'
ln -s '/usr/lib/systemd/system/mariadb.service' '/var/srvctl-rootfs/codepad/etc/systemd/system/multi-user.target.wants/mariadb.service'
ln -s '/usr/lib/systemd/system/codepad.service' '/var/srvctl-rootfs/codepad/etc/systemd/system/multi-user.target.wants/codepad.service'

    fi  
    
    ## other distros
    
    if [ ! -d /var/srvctl-rootfs/ubuntu ] || $all_arg_set
    then
        
        #rm -rf /var/srvctl-rootfs/ubuntu
        #rm -rf $TMP/ubuntu-cloud.tar.gz
        #wget -O $TMP/ubuntu-cloud.tar.gz https://cloud-images.ubuntu.com/releases/14.04/14.04.3/ubuntu-14.04-server-cloudimg-amd64-root.tar.gz
        #msg "Extracting .."
        #mkdir -p /var/srvctl-rootfs/ubuntu
        #tar --directory /var/srvctl-rootfs/ubuntu -xzf $TMP/ubuntu-cloud.tar.gz
        #rm -rf $TMP/ubuntu-cloud.tar.gz    
        #make_rootfs_config ubuntu ubuntu
    
          
          SRVCTL_PKG_LIST="mc apache2 nfs-kernel-server postfix dovecot-imapd dovecot-pop3d unzip rsync wget language-pack-en"
          mkrootfs_ubuntu ubuntu "$SRVCTL_PKG_LIST"       
          make_rootfs_config ubuntu ubuntu
          
          
        ## locale-gen en_US.UTF-8 
    fi
#source $install_dir/hs-install/lxc-apps.sh

