msg "Firewall"

## configure firewalld

services=" $(firewall-cmd --get-services) "
if [ -z "$(echo $services | grep ' http ')" ]
then
    echo firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=http
fi

if [ -z "$(echo $services | grep ' https ')" ]
then
    echo firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-service=https
fi

if [ -z "$(echo $services | grep ' imaps ')" ]
then
    echo firewall-cmd --permanent --add-service=imaps
    firewall-cmd --permanent --add-service=imaps
fi

if [ -z "$(echo $services | grep ' pop3s ')" ]
then
    echo firewall-cmd --permanent --add-service=pop3s
    firewall-cmd --permanent --add-service=pop3s
fi

if [ -z "$(echo $services | grep ' smtps ')" ]
then

    set_file /etc/firewalld/services/smtps.xml '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Mail - Secure (SMTPS)</short>
  <description>This option allows incoming secure SMTP mail delivery. (added by srvctl) </description>
  <port protocol="tcp" port="465"/>
</service>
'
    echo firewall-cmd --permanent --add-service=smtps
    firewall-cmd --permanent --add-service=smtps

fi


echo firewall-cmd --reload
firewall-cmd --reload

