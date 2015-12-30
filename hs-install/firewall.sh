add_service firewalld

zone=$(firewall-cmd --get-default-zone)
services=" $(firewall-cmd --zone=$zone --list-services) "

msg "Firewall $(firewall-cmd --state) - default zone: $zone"
echo $services
echo ''

echo Interfaces:
interfaces=$(firewall-cmd --list-interfaces)
for i in $interfaces
do
    echo $i - $(firewall-cmd --get-zone-of-interface=$i)
    echo ''
done

## configure firewalld --zone=$zone 

if [ -z "$(echo $services | grep ' http ')" ]
then
    echo firewall-cmd  --zone=$zone --permanent --add-service=http
    firewall-cmd  --zone=$zone --permanent --add-service=http
fi

if [ -z "$(echo $services | grep ' https ')" ]
then
    echo firewall-cmd --zone=$zone --permanent --add-service=https
    firewall-cmd --zone=$zone --permanent --add-service=https
fi

if [ -z "$(echo $services | grep ' imaps ')" ]
then
    echo firewall-cmd --zone=$zone --permanent --add-service=imaps
    firewall-cmd --zone=$zone --permanent --add-service=imaps
fi

if [ -z "$(echo $services | grep ' pop3s ')" ]
then
    echo firewall-cmd --zone=$zone --permanent --add-service=pop3s
    firewall-cmd --zone=$zone --permanent --add-service=pop3s
fi

if [ -z "$(echo $services | grep ' dns ')" ]
then
    echo firewall-cmd --permanent --add-service=dns
    firewall-cmd --permanent --add-service=dns
fi


if [ -z "$(echo $services | grep ' smtp ')" ]
then
    echo firewall-cmd --permanent --add-service=smtp
    firewall-cmd --permanent --add-service=smtp
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
    ## make firewall aware of the service
    echo firewall-cmd --reload
    firewall-cmd --reload

    echo firewall-cmd --zone=$zone --permanent --add-service=smtps
    firewall-cmd --zone=$zone --permanent --add-service=smtps

fi


echo firewall-cmd --reload
firewall-cmd --reload

