## @update-install
if [ -z "$(lxc-info --version 2> /dev/null)" ] || $all_arg_set
then
        log "Installing LXC!"

        if [ "$LXC_INSTALL" == "git" ] || [ "$LXC_INSTALL" == "src" ] || [ "$LXC_INSTALL" == "tar" ]
        then
                ## packages needed for compilation and for running
                log "Install Development Tools"
                pm groupinstall "Development Tools"
                exif
                pm install automake
                exif
                pm install graphviz
                exif
                pm install libcap-devel
                exif


                cd /root

                if [ "$LXC_INSTALL" == "git" ]
                then
                        log "Install LXC via git"
                          git clone git://github.com/lxc/lxc
                          exif
                fi

                if [ "$LXC_INSTALL" == "src" ]
                then
                        log "Installing using existing /root/lxc source."
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

                        dbg "LXC_VERSION: $LXC_VERSION"

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

                log "LXC-building: autogen"
                ./autogen.sh
                exif

                if [ ! -f /root/lxc/configure ]
                then
                        err "LXC-building: configure not found!"
                        exit 12
                fi

                log "LXC-building: configure"
                ./configure
                exif

                log "LXC-building: make"
                make
                exif

                log "LXC-building: install"
                make install
                exif
    
        else
                ## this is the default method
                log "install lxc $LXC_VERSION"

                if [ ! "$LXC_INSTALL" == 'latest-package' ]
                then
                        if [ "$LXC_VERSION" == "" ]
                        then
                                err 'LXC_VERSION not specified! CAN NOT use a release! exiting.'
                                exit 10
                        fi
                        pm install lxc-$LXC_VERSION
                        pm install lxc-extra-$LXC_VERSION
                        pm install lxc-templates-$LXC_VERSION
                else
                        pm install lxc
                        pm install lxc-extra
                        pm install lxc-templates
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

        add_conf /root/.bash_profile "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib"

        log "Configure libvirt network"
## Networking with libvirt
        
        ## ipcalc is provided by initscripts.
        pm install sipcalc
        
        ## network config validation

        if [ ! -z $(ipcalc -c -4 $HOSTIPv4) ]
        then
            err "Invalid srvctl config: HOSTIPv4 $HOSTIPv4"
            exit
        fi

        if [ ! -z $(ipcalc -c -6 $HOSTIPv6) ]
        then
            err "Invalid srvctl config: HOSTIPv6 $HOSTIPv6"
            exit
        fi

        if [ ! -z $(ipcalc -c -6 $RANGEv6) ]
        then
            err "Invalid srvctl config RANGEv6 $RANGEv6"
            exit
        fi
        
        pm install libvirt-daemon-driver-network libvirt-daemon-config-network libvirt-daemon-config-nwfilter

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

        systemctl enable libvirtd.service
        systemctl start  libvirtd.service
        systemctl status libvirtd.service
        
        #### RESTART REQUIRED HERE, if libvirt networks got modified.
        if ! $all_arg_set
        then
                log "LXC Installed. Please reboot, and run this command again to continiue. Exiting."
                exit
        fi
else
    msg "LXC is OK! "$(lxc-info --version)
fi ## Install LXC
