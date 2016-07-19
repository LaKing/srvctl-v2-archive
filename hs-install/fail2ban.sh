if [ ! -d /etc/fail2ban ]
then
        pm fail2ban

        cf=/etc/fail2ban/fail2ban.d/firewallcmd-ipset.conf
        wget -O $cf https://raw.githubusercontent.com/fail2ban/fail2ban/master/config/action.d/firewallcmd-ipset.conf

        cf=/etc/fail2ban/fail2ban.d/firewallcmd-new.conf
        wget -O $cf https://raw.githubusercontent.com/fail2ban/fail2ban/master/config/action.d/firewallcmd-new.conf


set_file /etc/fail2ban/jail.d/apache.conf '## srvctl
[apache-auth]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s


[apache-badbots]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_access_log)s
bantime  = 172800
maxretry = 1


[apache-noscript]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 6


[apache-overflows]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2


[apache-nohome]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2


[apache-botsearch]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2


[apache-modsecurity]
enabled = true
action = firewallcmd-ipset
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[php-url-fopen]
enabled = true
action = firewallcmd-ipset
port    = http,https
logpath = %(apache_access_log)s
'

set_file /etc/fail2ban/jail.d/perdition.conf '## srvctl
[perdition]
enabled = true
action = firewallcmd-ipset
port    = 995,143,993
'

set_file /etc/fail2ban/jail.d/postfix.conf '## srvctl 
[postfix]
enabled = true
action = firewallcmd-ipset
port    = 25,465,587

#logpath = %(sshd_log)s

[postfix-sasl]
enabled = true
action = firewallcmd-ipset
port     = 25,465,587,995,143,995
'

set_file /etc/fail2ban/jail.d/ssh.conf '[sshd]
enabled = true
action = firewallcmd-ipset
port    = ssh
'

set_file /etc/fail2ban/jail.local '[INCLUDES]

before = paths-fedora.conf

[DEFAULT]

ignoreip = 127.0.0.1/8 10.$HOSTNET.0.1/16
ignorecommand =
bantime  = 600
findtime  = 600
maxretry = 5
usedns = warn
logencoding = auto
enabled = false
filter = %(__name__)s
destemail = root@localhost
sender = root@localhost
mta = sendmail
protocol = tcp
chain = INPUT
port = 0:65535
banaction = iptables-multiport

action_ = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]

action_mw = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
            %(mta)s-whois[name=%(__name__)s, dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s"]

action_mwl = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             %(mta)s-whois-lines[name=%(__name__)s, dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]


action_xarf = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             xarf-login-attack[service=%(__name__)s, sender="%(sender)s", logpath=%(logpath)s, port="%(port)s"]

action_blocklist_de  = blocklist_de[email="%(sender)s", service=%(filter)s, apikey="%(blocklist_de_apikey)s"]
action_badips = badips.py[category="%(name)s", banaction="%(banaction)s"]
action = %(action_)s

## Jails in jail.d folder.
'

fi ## install fail2ban

## TODO: fail2ban seems to be resource hungry. :/

        ## Dev-note .. I was worried that unencrypted http between the host and a container can be sniffed from another container.
        ## My attempts to do so, did not work, therefore I kept this concept of the containers sitting together on srv-net with static IP's
        # .. also https is in use when using https on both sides of the proxy. 

