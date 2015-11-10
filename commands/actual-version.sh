#!/bin/bash

hint "version" "Display what srvctl version we are using."

if [ "$CMD" == "version" ]
then
  msg "Kernel: "$(uname -r)
  ver=$(head $0 | grep "# version ")
  msg "srvctl: $(cat $install_dir/version)"

  if $onHS
  then 

    if [ -z "$(lxc-info --version 2> /dev/null)" ]
    then
        err "LXC NOT INSTALLED!"
    else
        msg 'LXC: '$(lxc-info --version)' installed'
    fi
    msg_dnf_version_installed Pound
    pound -V 2> /dev/null | grep Version
    msg_dnf_version_installed postfix
    msg_dnf_version_installed perdition
    msg_dnf_version_installed fail2ban
    msg_dnf_version_installed bind
    msg_dnf_version_installed clamav
  fi

ok
fi

man '
    Display kernel version, srvctl version
    Pound, postfix, perdition, fail2ban, bind, clamav versions
'


