## @update-install
if [ -z "$(lxc-info --version 2> /dev/null)" ] || $all_arg_set
then
        msg "Installing LXC!"

        if [ "$LXC_INSTALL" == "git" ] || [ "$LXC_INSTALL" == "src" ] || [ "$LXC_INSTALL" == "tar" ]
        then
                ## packages needed for compilation and for running
                msg "Install Development Tools"
                dnf -y groupinstall "Development-Tools"
                exif
                pm automake
                exif
                pm graphviz
                exif
                pm libcap-devel
                exif
                
                if $all_arg_set
                then
                    ## remove packages
                    dnf -y remove lxc*
                    ## configs might containe /usr/share we might need /user/local/share
                    ## regenerate will make new configs
                    rm -rf $SRV/*/config
                fi

                cd /root
                
                add_conf /root/.bash_profile 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib'

                if [ "$LXC_INSTALL" == "git" ]
                then
                        msg "Install LXC via git"
                          git clone git://github.com/lxc/lxc
                          exif
                fi

                if [ "$LXC_INSTALL" == "src" ]
                then
                        msg "Installing using existing /root/lxc source."
                fi

                if [ "$LXC_INSTALL" == "tar" ]
                then

                        if [ "$LXC_VERSION" == "" ]
                        then
                                err 'LXC_VERSION not specified! CAN NOT use a release! exiting.'
                                exit 10
                        fi

                        if $all_arg_set
                        then
                                rm -rf lxc
                        fi

                        ## use a version-release
                        if [ ! -f "/root/lxc-$LXC_VERSION.tar.gz" ] 
                        then 
                                msg "Downloading LXC $LXC_VERSION"
                                wget -O /root/lxc-$LXC_VERSION.tar.gz https://linuxcontainers.org/downloads/lxc/lxc-$LXC_VERSION.tar.gz
                                exif
                        fi
                        
                        if [ ! -d "/root/lxc" ]
                        then
                                tar -zxvf /root/lxc-$LXC_VERSION.tar.gz
                                mv /root/lxc-$LXC_VERSION /root/lxc
                        fi
                                    
                                ## This seems to be obsolete
                                ## wget -O /root/lxc-$LXC_VERSION.zip https://github.com/lxc/lxc/archive/lxc-$LXC_VERSION.zip
                                ##unzip /root/lxc-$LXC_VERSION.zip                    
                        
                        
                fi
         
                cd /root/lxc

                if [ ! -f /root/lxc/autogen.sh ]
                then
                        err "LXC-building: autogen.sh not found!"
                        exit 11
                fi

                msg "LXC-building: autogen"
                ./autogen.sh
                exif

                if [ ! -f /root/lxc/configure ]
                then
                        err "LXC-building: configure not found!"
                        exit 12
                fi

                msg "LXC-building: configure"
                ./configure
                exif

                msg "LXC-building: make"
                make
                exif

                msg "LXC-building: install"
                make install
                exif
    
        else
                ## this is the default method
                msg "install lxc $LXC_VERSION"

                if [ ! "$LXC_INSTALL" == 'latest-package' ]
                then
                        if [ "$LXC_VERSION" == "" ]
                        then
                                err 'LXC_VERSION not specified! CAN NOT use a release! exiting.'
                                exit 10
                        fi
                        pm lxc-$LXC_VERSION
                        pm lxc-extra-$LXC_VERSION
                        pm lxc-templates-$LXC_VERSION
                else
                        pm lxc
                        pm lxc-extra
                        pm lxc-templates
                fi                 
        fi
        
        ## default path for containers - source install
        if [ -f "/usr/local/etc/lxc/default.conf" ]
        then        
                set_file "/usr/local/etc/lxc/lxc.conf" "lxc.lxcpath=$SRV" 
        fi        
        ## package install
        if [ -f "/etc/lxc/default.conf" ]
        then                        
                set_file "/etc/lxc/lxc.conf" "lxc.lxcpath=$SRV" 
        fi


        msg "Configure libvirt network"
## Networking with libvirt
        
        ## ipcalc is provided by initscripts.
        pm sipcalc

        
        pm libvirt-daemon-driver-network libvirt-daemon-config-network libvirt-daemon-config-nwfilter

        ## DHCP is only for manually created containers. srvctl containers should use static ip addresses.
        
        set_file /etc/libvirt/qemu/networks/default.xml '<network>
  <name>default</name>
  <uuid>00000000-0000-aaaa-aaaa-aaaaaaaaaaaa</uuid>
  <bridge name="inet-br"/>
  <mac address="00:00:00:AA:AA:AA"/>
  <forward/>
  <ip address="192.168.0.1" netmask="255.255.0.0">
    <dhcp>
      <range start="192.168.0.2" end="192.168.0.254"/>
    </dhcp>
  </ip>
</network>
'
set_file /etc/libvirt/qemu/networks/primary.xml '<network>
  <name>primary</name>
  <uuid>00000000-0000-2010-0010-000000000001</uuid>
  <bridge name="srv-net"/>
  <mac address="00:00:10:10:00:01"/>
  <forward/>
  <ip address="10.10.0.1" netmask="255.255.0.0"></ip>
</network>
'

# <ip family="ipv6" address="'$RANGEv6'" prefix="'$PREFIXv6'"></ip>

## TODO, .. consider to set a new bridge for ipv6 - or set up a route ...
## ipv4 needs NAT (forward) but ipv6 does not ...

#<network ipv6='yes'>
#  <name>primary</name>
#  <uuid>00000000-0000-2010-0010-000000000001</uuid>
#  <bridge name="srv-net"/>
#  <mac address="00:00:10:10:00:01"/>
#  <forward/>
#  <ip address="10.10.0.1" netmask="255.255.0.0"></ip>
#  <ip family="ipv6" address="2001: ... :1" prefix="64" />
#</network>

        ln -s /etc/libvirt/qemu/networks/primary.xml /etc/libvirt/qemu/networks/autostart/primary.xml 2> /dev/null

        add_service libvirtd
        
        #### RESTART REQUIRED HERE, if libvirt networks got modified.
        if [ -z "$(ip addr show srv-net 2> /dev/null | grep UP)" ]
        then
                err "srv-net not found. It will be active after reboot."
                msg "LXC Installed. Please reboot, and run this command again to continiue. Exiting."
                exit
        fi
else
    msg "LXC is OK! "$(lxc-info --version)
fi ## Install LXC


