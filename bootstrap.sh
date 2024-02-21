#! /bin/bash

#####################################################################
#                                                                   #
# Author:       Martin Boller                                       #
#                                                                   #
# Email:        martin                                              #
# Last Update:  2024-02-18                                          #
# Version:      1.00                                                #
#                                                                   #
# Changes:      First version (1.00)                                #
#                                                                   #
#                                                                   #
#####################################################################

configure_locale() {
  /usr/bin/logger 'configure_locale()' -t 'misp';
  echo -e "\e[32m - configure_locale()\e[0m";
  echo -e "\e[36m ... configure locale (default:C.UTF-8)\e[0m";
  export DEBIAN_FRONTEND=noninteractive;
  sh -c "cat << EOF  > /etc/default/locale
# /etc/default/locale
LANG=C.UTF-8
LANGUAGE=C.UTF-8
LC_ALL=C.UTF-8
EOF";
  update-locale > /dev/null 2>&1;
  echo -e "\e[32m - configure_locale() finished\e[0m";
  /usr/bin/logger 'configure_locale() finished' -t 'misp';
}

configure_timezone() {
  /usr/bin/logger 'configure_timezone()' -t 'misp';
  echo -e "\e[32m - configure_timezone()\e[0m";
  echo -e "\e[36m ... set timezone to Etc/UTC\e[0m";
  export DEBIAN_FRONTEND=noninteractive;
  timedatectl set-timezone UTC;
  rm /etc/localtime > /dev/null 2>&1;
  echo 'Etc/UTC' > /etc/timezone > /dev/null 2>&1;
  dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1;
  echo -e "\e[32m - configure_timezone() finished\e[0m";
  /usr/bin/logger 'configure_timezone() finished' -t 'misp';
}

misp_bootstrap_prerequisites() {
  /usr/bin/logger 'misp_bootstrap_prerequisites()' -t 'misp';
  echo -e "\e[32m - misp_bootstrap_prerequisites()\e[0m";

  # Install prerequisites and useful tools
  export DEBIAN_FRONTEND=noninteractive;
  #sed -ie s/http/https/ /etc/apt/sources.list;
  apt-get -qq update > /dev/null 2>&1;
  # Removing some of the cruft installed by default in the Vagrant images
  echo -e "\e[36m ... cleaning up apt\e[0m";
  #apt-get -qq -y install --fix-policy > /dev/null 2>&1;
  apt-get -qq update > /dev/null 2>&1;
  apt-get -qq -y full-upgrade > /dev/null 2>&1
  apt-get -qq -y --purge autoremove > /dev/null 2>&1
  apt-get -qq autoclean > /dev/null 2>&1
  sync > /dev/null 2>&1
  apt-get -qq -y install git rhash > /dev/null 2>&1;
  /usr/bin/logger 'install_updates()' -t 'misp';
  # get MISP install from github
  echo -e "\e[36m ... copying MISP\e[0m";
  git clone https://github.com/SteveClement/xsnippet.git
  cp /home/vagrant/xsnippet/xsnippet /usr/local/sbin/;
  #Create misp user
  /usr/sbin/useradd --system --create-home -c "MISP User" --shell /bin/bash misp > /dev/null 2>&1;

  echo -e "\e[32m - misp_bootstrap_prerequisites()\e[0m";
  /usr/bin/logger 'misp_bootstrap_prerequisites() finished' -t 'misp';
}

prepare_nix() {
  /usr/bin/logger 'prepare_nix()' -t 'misp';
  echo -e "\e[32m - prepare_nix()\e[0m";
  
  echo -e "\e[1;36m...creating sudoers.d/misp file\e[0m";
  # sudoers.d to run openvas as root
  cat << __EOF__ > /etc/sudoers.d/misp
misp    ALL=(ALL) NOPASSWD:ALL
__EOF__
  sync;

  /usr/bin/logger 'prepare_nix() finished' -t 'misp';
  echo -e "\e[32m - prepare_nix() finished\e[0m";
}

install_misp() {
  /usr/bin/logger 'install_misp()' -t 'misp';
  echo -e "\e[32m - install_misp()\e[0m";

  # Clone repository
  su - misp -c 'git clone https://github.com/MISP/MISP.git --recurse-submodules';
  su - misp -c '~/MISP/INSTALL/INSTALL.tpl.sh';
  su - misp -c '~/MISP/INSTALL/INSTALL.sh -u -A';

  /usr/bin/logger 'install_misp() finished' -t 'misp';
  echo -e "\e[32m - install_misp() finished\e[0m";
}

configure_misp() {
  /usr/bin/logger 'configure_misp()' -t 'misp';
  echo -e "\e[32m - configure_misp()\e[0m";

  # bsecure specifics
  sed -i "s/serveradmin@misp.local/$mymispUser@$mymispOrganization/" /etc/apache2/sites-available/misp-ssl.conf;
  sed -iE "s/ServerName\smisp.local/ServerName $(hostname --fqdn)/" /etc/apache2/sites-available/misp-ssl.conf;
  sed -i "s/This is an initial install/Cyber Threat Intelligence /" /var/www/MISP/app/Config/config.php
  sed -i "s/Please configure and harden accordingly/$mymispOrganization/" /var/www/MISP/app/Config/config.php
  sed -i "s/ORGNAME/$mymispOrganization/" /var/www/MISP/app/Config/config.php
  sed -i "s/Initial Install, please configure//" /var/www/MISP/app/Config/config.php
  sed -i "s/Welcome to MISP on ubuntu, change this message in MISP Settings/bsecure.dk Threat Intel Platform Powered by MISP/" /var/www/MISP/app/Config/config.php
  /usr/bin/logger 'configure_misp() finished' -t 'misp';
  echo -e "\e[32m - configure_misp() finished\e[0m";
}

install_public_ssh_keys() {
  /usr/bin/logger 'install_public_ssh_keys()' -t 'misp';
  echo -e "\e[32m - install_public_ssh_key()\e[0m";

  # Echo add SSH public key for root logon
  export DEBIAN_FRONTEND=noninteractive;
  echo -e "\e[36m ... adding authorized_keys file and setting permissions\e[0m";
  mkdir /root/.ssh > /dev/null 2>&1;
  echo $myPublicSSHKey | tee -a /root/.ssh/authorized_keys > /dev/null 2>&1;
  chmod 700 /root/.ssh > /dev/null 2>&1;
  chmod 600 /root/.ssh/authorized_keys > /dev/null 2>&1;

  echo -e "\e[32m - install_public_ssh_key() finished\e[0m";
  /usr/bin/logger 'install_public_ssh_keys() finished' -t 'misp';
}

configure_vagrant() {
  /usr/bin/logger 'configure_vagrant()' -t 'misp';
  echo -e "\e[32mconfigure_vagrant()\e[0m";

  echo "export VAGRANT_ENV=TRUE" > /etc/profile.d/vagrant.sh;
  touch /etc/VAGRANT_ENV > /dev/null 2>&1;

  echo -e "\e[32mconfigure_vagrant() finished\e[0m";
  /usr/bin/logger 'configure_vagrant() finished' -t 'misp';
}

##################################################################################################################
## Main                                                                                                          #
##################################################################################################################

main() {
    echo -e "\e[32m - MISP Installation Bootstrap\e[0m";

    # Shared variables
    export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    # Configure environment from .env file
    set -a; source $SCRIPT_DIR/installfiles/.env;
    echo -e "\e[1;36m....env file version $ENV_VERSION used\e[0m"

    # Core elements, always installs
    /usr/bin/logger 'MISP Bootstrap main()' -t 'misp';
    prepare_nix;
    configure_vagrant;
    install_public_ssh_keys;
    misp_bootstrap_prerequisites;
    
    echo -e "\e[36m ... Installing MISP server\e[0m";    
    install_misp;
    configure_misp;
    
    echo -e "\e[32m - MISP Bootstrap main() finished\e[0m";
    /usr/bin/logger 'MISP Installation Bootstrap main() finished' -t 'misp';
}

main;

exit 0
