add_service firewalld

zone=$(firewall-cmd --get-default-zone)
services="services: $(firewall-cmd --zone=$zone --list-services) ."

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
    echo firewall-cmd --zone=$zone  --permanent --add-service=dns
    firewall-cmd --zone=$zone --permanent --add-service=dns
fi

if [ -z "$(echo $services | grep ' openvpn ')" ]
then
    echo firewall-cmd --zone=$zone --permanent --add-service=openvpn
    firewall-cmd --zone=$zone --permanent --add-service=openvpn
fi

if [ -z "$(echo $services | grep ' smtp ')" ]
then
    echo firewall-cmd --zone=$zone --permanent --add-service=smtp
    firewall-cmd --zone=$zone --permanent --add-service=smtp
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

if [ -z "$(echo $services | grep ' dyndns ')" ]
then

    set_file /etc/firewalld/services/dyndns.xml '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Dyndns-server</short>
  <description>This option allows logging of IP addresses for dyndns use. (added by srvctl) </description>
  <port protocol="tcp" port="855"/>
</service>
'
    ## make firewall aware of the service
    echo firewall-cmd --reload
    firewall-cmd --reload

    echo firewall-cmd --zone=$zone --permanent --add-service=dyndns
    firewall-cmd --zone=$zone --permanent --add-service=dyndns
fi


if [ -z "$(echo $services | grep ' srvctl-gui ')" ]
then
    set_file /etc/firewalld/services/srvctl-gui.xml '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>srvctl-gui</short>
  <description>This option allows the use of srvctl on a browser. </description>
  <port protocol="tcp" port="250"/>
</service>
'
    ## make firewall aware of the service
    echo firewall-cmd --reload
    firewall-cmd --reload

    echo firewall-cmd --zone=$zone --permanent --add-service=srvctl-gui
    firewall-cmd --zone=$zone --permanent --add-service=srvctl-gui
fi

if [ -z "$(echo $services | grep ' usernet-openvpn ')" ]
then

    set_file /etc/firewalld/services/usernet-openvpn.xml '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>usernet-openvpn</short>
  <description>Openvpn connection directly to containers. </description>
  <port protocol="udp" port="1100"/>
</service>
'
    ## make firewall aware of the service
    echo firewall-cmd --reload
    firewall-cmd --reload

    echo firewall-cmd --zone=$zone --permanent --add-service=usernet-openvpn
    firewall-cmd --zone=$zone --permanent --add-service=usernet-openvpn
fi

if [ -z "$(echo $services | grep ' hostnet-openvpn ')" ]
then

    set_file /etc/firewalld/services/hostnet-openvpn.xml '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>hostnet-openvpn</short>
  <description>Openvpn connection between hosts. </description>
  <port protocol="udp" port="1101"/>
</service>
'
    ## make firewall aware of the service
    echo firewall-cmd --reload
    firewall-cmd --reload

    echo firewall-cmd --zone=$zone --permanent --add-service=hostnet-openvpn
    firewall-cmd --zone=$zone --permanent --add-service=hostnet-openvpn
fi

echo firewall-cmd --reload
firewall-cmd --reload

