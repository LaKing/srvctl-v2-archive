## configure DNS server
## no recursion to prevent DNS amplifiaction attacks
if [ ! -f /etc/named.conf ] || $all_arg_set
then
        log "Installing BIND (named) DNS server."

        pm bind bind-utils
        pm ntp
        
        add_service ntpd
        
        ## DNS needs NTPD enabled and running, otherwise queries may get no response.
        
        set_file /etc/named.conf '// srvctl generated named.conf

acl "trusted" {
     10.'$HOSTNET'.0.0/16;
     localhost;
     localnets;
 };

options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory         "/var/named";
    dump-file         "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query     { any; };
    allow-recursion { trusted; };
    allow-query-cache { trusted; };
    recursion yes;
    dnssec-enable yes;
    dnssec-validation yes;
    dnssec-lookaside auto;
    bindkeys-file "/etc/named.iscdlv.key";
    managed-keys-directory "/var/named/dynamic";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

include "/var/named/srvctl-includes.conf";
'

set_file /var/srvctl-host/named.conf.local '## srvctl generated 
'

        rsync -a /usr/share/doc/bind/sample/etc/named.rfc1912.zones /etc
        rsync -a /usr/share/doc/bind/sample/var/named /var
        mkdir -p /var/named/dynamic

        chown -R named:named /var/named #?/srvctl
        chmod 750 /var/named/srvctl
        add_service named
else
    msg "Bind - DNS server already configured."
fi ## install named


## dyndns stuff

if [ ! -f /lib/systemd/system/dyndns-server.service ]
then
    log "Installing BIND based dyndns."
 
        mkdir -p /var/dyndns
    chown node:root /var/dyndns
    chmod 754 /var/dyndns

    set_file /lib/systemd/system/dyndns-server.service '## srvctl generated
[Unit]
Description=Dyndns server.
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/bin/node '$install_dir'/hs-apps/dyndns-server.js /etc/srvctl/cert/'$CDN/$CDN'.key /etc/srvctl/cert/'$CDN/$CDN'.crt
User=root
Group=root

[Install]
WantedBy=multi-user.target
'

    systemctl daemon-reload
    add_service dyndns-server

fi

if [ ! -d /var/named/keys ]
then
    mkdir -p /var/named/keys
    _this="$(dnssec-keygen -K /var/named/keys -r /dev/urandom -a HMAC-MD5 -b 512 -n USER srvctl)"
    cat /var/named/keys/$_this.key > /var/named/keys/srvctl.key
    cat /var/named/keys/$_this.private > /var/named/keys/srvctl.private
    
    chown node /var/dyndns/srvctl.private
    chmod 400 /var/dyndns/srvctl.private
    
    _key="$(cat /var/named/keys/$_this.private | grep 'Key: ')"

set_file /var/named/srvctl-include-key.conf '## srvctl dyndns key
key "srvctl." {
  algorithm hmac-md5;
  secret "'${_key:5}'";
};
'
        ## use it in dyndns-server
        cat /var/named/srvctl-include-key.conf > /var/dyndns/srvctl-include-key.conf
        chown node:node /var/dyndns/srvctl-include-key.conf
        chmod 400 /var/dyndns/srvctl-include-key.conf
    
        ## named needs to write to these folders for dyndns
        chown -R named:named /var/named #?/srvctl
        chmod 750 /var/named/srvctl
fi

