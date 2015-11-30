
if [ ! -f /etc/freshclam.conf ] || $all_arg_set
then

msg "Installing antivirus software"

pm clamav clamav-update
sed_file /etc/freshclam.conf "Example" "### Exampl."
sed_file /etc/freshclam.conf "#DNSDatabaseInfo current.cvd.clamav.net" "DNSDatabaseInfo current.cvd.clamav.net"

echo freshclam
freshclam
 
## http://www.server-world.info/en/note?os=Fedora_21&p=mail&f=6
log "Install virus-scanners"
pm amavisd-new
pm clamav-server-systemd

add_service amavisd
add_service spamassassin

/sbin/chkconfig amavisd on
/sbin/chkconfig clamd.amavisd on

## TODO here - check / enable it for real
systemctl enable clamd@amavisd 
systemctl start clamd@amavisd 
systemctl status clamd@amavisd 

sed_file /etc/amavisd/amavisd.conf "mydomain = 'example.com';   " "mydomain = '$CDN';   "
sed_file /etc/amavisd/amavisd.conf "# myhostname = 'host.example.com';  " "myhostname = '$(hostname)';  "

# $notify_method  = 'smtp:[127.0.0.1]:10025';
# $forward_method = 'smtp:[127.0.0.1]:10025';  # set to undef with milter!

else
    msg "Antivirus software installed."
    echo freshclam
    freshclam
fi




