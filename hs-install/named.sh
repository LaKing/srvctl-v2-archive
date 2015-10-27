## configure DNS server
## no recursion to prevent DNS amplifiaction attacks
if [ ! -f /etc/named.conf ] || $all_arg_set
then
        log "Installing BIND (named) DNS server."

        pm bind bind-utils
        pm ntp
        
        systemctl start ntpd.service
        systemctl enable ntpd.service
        
        ## DNS needs NTPD enabled and running, otherwise queries may get no response.
        
        set_file /etc/named.conf '// srvctl generated named.conf

acl "trusted" {
     10.10.0.0/16;
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

include "/etc/srvctl/named.conf.local";
'

set_file /etc/srvctl/named.conf.local '## srvctl generated 
'

        rsync -a /usr/share/doc/bind/sample/etc/named.rfc1912.zones /etc
        rsync -a /usr/share/doc/bind/sample/var/named /var
        mkdir -p /var/named/dynamic

        chown -R named:named /var/named
else
    msg "Bind - DNS server already configured."
fi ## install named

