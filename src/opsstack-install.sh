#!/bin/bash

##################################
#
# OpsStack Master Install Script
#
# Copyright 2016-2017 OpsStack
##################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helpers
error() {
    echo ""
    printf "${RED}  !! ${1}${NC}\n"
    echo ""
    printf "${RED}  !! Exiting...${NC}\n"
    exit 1
}

msg() {
    echo ""
    printf "${GREEN}  => ${1}${NC}\n"
}

msg_progress() {
    echo ""
    printf "${GREEN}  => ${1}${NC}   "
}

msg_okay() {
    printf "${GREEN} OK ${NC}\n"
}
msg_err() {
    printf "${RED} FAIL ${NC}\n"
}
msg_skip() {
    printf "${YELLOW} SKIP ${NC}\n"
}

##############
# MAIN Start #
##############

# Hello
printf "\n"
printf "${YELLOW}############################################################${NC}\n"
printf "Welcome to OpsStack - Unified Operations Platform\n"
printf "                 www.OpsStack.io\n"
printf "Docs at: https://opsstack.readme.io/docs/getting-started\n"
printf "${YELLOW}############################################################${NC}\n"

# Check if running as root or with sudo
msg_progress "Checking if we are root/sudo ..."
if [[ ! `id -u` = 0 ]] ; then
    msg_err
    error "We need to run as root or sudo."
fi
msg_okay

# Check which Linux distribution and version
# and save them to variables
msg_progress "Checking Linux platform..."
if [[ -f "/etc/redhat-release" ]] ; then
    # Apparently redhat, but which one?
    grep "CentOS" /etc/redhat-release > /dev/null 2>&1
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        OS="CentOS"
        # And what version
        if [[ `cat /etc/redhat-release | awk '{print $3}'` == 6* ]] ; then
            OSVER="6"
        elif [[ `cat /etc/redhat-release | awk '{print $4}'` == 7* ]] ; then
            OSVER="7"
        else
            msg_err
            error "This CentOS version not supported. Please contact support."
        fi
    else
        OS="RHEL"
        # We are RHEL, so what version
        if [[ `cat /etc/redhat-release | awk '{print $7}'` == 6* ]] ; then
            OSVER="6"
        elif [[ `cat /etc/redhat-release | awk '{print $7}'` == 7* ]] ; then
            OSVER="7"
        else
            msg_err
            error "This Red Hat version not supported. Please contact support."
        fi
    fi
elif [[ -f '/etc/system-release' ]] && [[ `cat /etc/system-release` == Amazon* ]] ; then
    # Definitely Amazon Linux then
    OS="Amazon Linux"
    # So what version
    if [[ `cat /etc/system-release | awk '{print $5}'` == 2016* ]] ; then
        OSVER="2016"
    elif [[ `cat /etc/system-release | awk '{print $5}'` == 2017* ]] ; then
        OSVER="2017"
    # 2015 is last or else will error on cat redhat-release
    elif [[ `cat /etc/redhat-release | awk '{print $3}'` == 2015* ]] ; then
        OSVER="2015"
    else
        msg_err
        error "This Amazon Linux version not supported. Please contact support."
    fi
elif [[ -f '/etc/debian_version' ]]; then
    # Apparently debian, but which one?
    command -V lsb_release > /dev/null 2>&1
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        OS_DESC=`lsb_release -i | awk '{print $3}'`
        OS_RELEASE=`lsb_release -r | awk '{print $2}'`
        if [[ ${OS_DESC} == Ubuntu* ]]; then
            OS="Ubuntu"
            OSVER=${OS_RELEASE}
            if [[ ${OS_RELEASE} == 12.* ]]; then
                UBUNTU_OSVER="precise"
            elif [[ ${OS_RELEASE} == 14.* ]]; then
                UBUNTU_OSVER="trusty"
            elif [[ ${OS_RELEASE} == 16.* ]]; then
                UBUNTU_OSVER="xenial"
            else
                msg_err
                error "This Ubuntu Linux version not supported. Please contact support."
            fi
        elif [[ ${OS_DESC} == Debian* ]]; then
            OS="Debian"
            OSVER=${OS_RELEASE}
            if [[ ${OS_RELEASE} == 8.* ]]; then
                DEBIAN_OSVER="jessie"
            elif [[ ${OS_RELEASE} == 7.* ]]; then
                DEBIAN_OSVER="wheezy"
            else
                msg_err
                error "Unsupported Debian Version.  Please contact support."
            fi
        else
            msg_err
            error "Unsupported Debian Version. Please contact support."
        fi
    else
        if [[ `cat /etc/debian_version` == [jsw]* ]]; then
            OS="Ubuntu"
            if [[ `cat /etc/debian_version` == wheezy* ]]; then
                OSVER="12"
                UBUNTU_OSVER="precise"
            elif [[ `cat /etc/debian_version` == jessie* ]]; then
                OSVER="14"
                UBUNTU_OSVER="trusty"
            elif [[ `cat /etc/debian_version` == stretch* ]]; then
                OSVER="16"
                UBUNTU_OSVER="xenial"
            else
                msg_err
                error "Ubuntu Linux version not supported. Please refer to documentation."
            fi
        elif [[ `cat /etc/debian_version` == [78].* ]]; then
            OS="Debian"
            OSVER=`cat /etc/debian_version`
            if [[ `cat /etc/debian_version` == 7.* ]]; then
                DEBIAN_OSVER="wheezy"
            elif [[ `cat /etc/debian_version` == 8.* ]]; then
                DEBIAN_OSVER="jessie"
            else
                msg_err
                error "Unsupported Debian Version. Please contact support."
            fi
        else
            msg_err
            error "Unsupported Debian Version. Please contact support."
        fi
    fi
else
    msg_err
    error "Unsupported Linux distribution. Please contact support."
fi
msg_okay

# TODO: Check connection to opsstack and zabbix

# TODO: Update these repos based  on environment / region

# Show detected system information
msg "Detected $OS version $OSVER"

# Install repository
msg_progress "Adding repositories ..."
if [[ ${OS} == "CentOS" ]] || [[ ${OS} == "RHEL" ]] ; then
    REPO="http://repo.service.chinanetcloud.com/yum/el${OSVER}/base/x86_64/nc-repo-1.0.0-1.el${OSVER}.noarch.rpm"
    # Check if repo already installed
    rpm -qa | grep nc-repo  > /dev/null 2>&1
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        yum reinstall ${REPO} -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    else
        yum install ${REPO} -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Amazon Linux" ]] ; then
    REPO="http://repo.service.chinanetcloud.com/yum/amzn/base/x86_64/nc-repo-1.0.0-1.amzn.noarch.rpm"
    # Check if repo already installed
    rpm -qa | grep nc-repo  > /dev/null 2>&1
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        yum reinstall ${REPO} -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    else
        yum install ${REPO} -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Ubuntu" ]] ; then
    REPO="http://repo.service.chinanetcloud.com/apt/ubuntu/pool/${UBUNTU_OSVER}/main/nc-repo_1.0.0-1.ubuntu%2B${UBUNTU_OSVER}_all.deb"
    # Download repo package and install it
    wget -q ${REPO} -O /tmp/nc-repo_1.0.0-1.ubuntu.deb > /dev/null 2>&1
    RES=$?
    if [[ ! ${RES} = 0 ]] ; then
        msg_err
        error "Error downloading nc-repo package. Please refer to documentation."
    else
        dpkg -i /tmp/nc-repo_1.0.0-1.ubuntu.deb > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
                msg_err
                error "Error installing repository. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Debian" ]] ; then
    REPO="http://repo.service.chinanetcloud.com/apt/debian/pool/${DEBIAN_OSVER}/main/nc-repo_1.0.0-1.debian%2B${DEBIAN_OSVER}_all.deb"
    # Download repo package and install it
    wget -q ${REPO} -O /tmp/nc-repo_1.0.0-1.debian.deb > /dev/null 2>&1
    RES=$?
    if [[ ! ${RES} = 0 ]] ; then
        msg_err
        error "Error downloading nc-repo package. Please refer to documentation."
    else
        dpkg -i /tmp/nc-repo_1.0.0-1.debian.deb > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
                msg_err
                error "Error installing repository. Please refer to documentation."
        fi
    fi
fi
msg_okay

# Install packages
msg_progress "Installing OpsStack packages..."
if [[ ${OS} == "CentOS" ]] || [[ ${OS} == "RHEL" ]] || [[ ${OS} == "Amazon Linux" ]] ; then
    # Check if package already installed
    rpm -qa | grep opsstack-tools > /dev/null 2>&1
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        yum reinstall opsstack-tools -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing packages. Please refer to documentation."
        fi
    else
        yum install opsstack-tools -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing packages. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Ubuntu" ]] || [[ ${OS} == "Debian" ]]; then
    # Before installing package, update repository first
    apt-get update > /dev/null 2>&1
    # Check if package already installed
    dpkg -l |grep opsstack-tools > /dev/null 2>&1
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        apt-get install --reinstall opsstack-tools -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing packages. Please refer to documentation."
        fi
    else
        apt-get install opsstack-tools -y > /dev/null 2>&1
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing packages. Please refer to documentation."
        fi
    fi
fi
msg_okay

# Show information
msg "Everything installed, now executing opsstack-configure to register system"
echo ""
echo ""
printf "${YELLOW}#############################################${NC}\n"
echo ""
echo ""

# Get Environment

echo "Which OpsStack Region are you in ?"
echo "1) USA"
echo "2) China"
echo ""
read -p 'Region Num: ' regionenv

CONFIGARG=''
if [ "$regionenv" == "1" ]; then
  REGION='USA'
  CONFIGARG='--usa'
elif [ "$regionenv" == "2" ]; then
  REGION="China"
  CONFIGARG=''
elif [ "$regionenv" == "3" ]; then
  REGION="Dev"
  CONFIGARG='--dev'
else
  echo "Bad Selection - Exiting"
  exit 1
fi

printf "\nYour Region is: $REGION \n\n"

# Execute opsstack-configure
opsstack-configure $CONFIGARG
RES=$?

echo ""
msg "opsstack-configure finished"
echo ""

# Execute opsstack-install only if opsstack-configure exit with 0
if [[ ${RES} = 0 ]]; then
    echo ""
    msg "Executing opsstack-install to add monitoring, collectors, syslog, nctop"
    echo ""
    # Execute opsstack-install
    opsstack-install $CONFIGARG
    RES=$?
fi

echo ""
msg "opsstack-install finished"
echo ""

exit ${RES}
