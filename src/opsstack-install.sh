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
printf "Docs at: http://read.corilla.com/OpsStack/Documentation.html\n"
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
    out=$(grep "CentOS" /etc/redhat-release 2>&1)
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
    elif [[ `cat /etc/system-release | awk '{print $5}'` == 2018* ]] ; then
        OSVER="2018"
    elif [[ `cat /etc/system-release ` == "Amazon Linux 2" ]] ; then
        OSVER="2"
    else
        msg_err
        error "This Amazon Linux version not supported. Please contact support."
    fi
elif [[ -f '/etc/debian_version' ]]; then
    # Apparently debian, but which one?
    out=$(command -V lsb_release 2>&1)
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
            elif [[ ${OS_RELEASE} == 18.* ]]; then
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
        msg_err
        error "lsb_release is missing, please install corresponding dependencies."
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
    out=$(rpm -qa | grep nc-repo 2>&1)
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        out=$(yum reinstall ${REPO} -y 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    else
        out=$(yum install ${REPO} -y 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Amazon Linux" ]] ; then
    if [[ ${OSVER} == "2" ]];then
        REPO="http://repo.service.chinanetcloud.com/yum/el7/base/x86_64/nc-repo-1.0.0-1.el7.noarch.rpm"
    else
        REPO="http://repo.service.chinanetcloud.com/yum/amzn/base/x86_64/nc-repo-1.0.0-1.amzn.noarch.rpm"
    fi
    # Check if repo already installed
    out=$(rpm -qa | grep nc-repo 2>&1)
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        out=$(yum reinstall ${REPO} -y 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    else
        out=$(yum install ${REPO} -y 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing repository. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Ubuntu" ]] ; then
    REPO="http://repo.service.chinanetcloud.com/apt/ubuntu/pool/${UBUNTU_OSVER}/main/nc-repo_1.0.0-1.ubuntu%2B${UBUNTU_OSVER}_all.deb"
    # Download repo package and install it
    out=$(wget -q ${REPO} -O /tmp/nc-repo_1.0.0-1.ubuntu.deb 2>&1)
    RES=$?
    if [[ ! ${RES} = 0 ]] ; then
        msg_err
        error "Error downloading nc-repo package. Please refer to documentation."
    else
        out=$(dpkg -i /tmp/nc-repo_1.0.0-1.ubuntu.deb 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
                msg_err
                error "Error installing repository. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Debian" ]] ; then
    REPO="http://repo.service.chinanetcloud.com/apt/debian/pool/${DEBIAN_OSVER}/main/nc-repo_1.0.0-1.debian%2B${DEBIAN_OSVER}_all.deb"
    # Download repo package and install it
    out=$(wget -q ${REPO} -O /tmp/nc-repo_1.0.0-1.debian.deb 2>&1)
    RES=$?
    if [[ ! ${RES} = 0 ]] ; then
        msg_err
        error "Error downloading nc-repo package. Please refer to documentation."
    else
        out=$(dpkg -i /tmp/nc-repo_1.0.0-1.debian.deb 2>&1)
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
    out=$(rpm -qa | grep opsstack-tools 2>&1)
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        out=$(yum reinstall opsstack-tools -y 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing packages. Please refer to documentation."
        fi
    else
        out=$(yum install opsstack-tools -y 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing packages. Please refer to documentation."
        fi
    fi
elif [[ ${OS} == "Ubuntu" ]] || [[ ${OS} == "Debian" ]]; then
    # Before installing package, update repository first
    out=$(apt-get update 2>&1)
    # Check if package already installed
    out=$(dpkg -l | grep opsstack-tools 2>&1)
    RES=$?
    if [[ ${RES} = 0 ]] ; then
        out=$(apt-get install --reinstall opsstack-tools -y 2>&1)
        RES=$?
        if [[ ! ${RES} = 0 ]] ; then
            msg_err
            error "Error installing packages. Please refer to documentation."
        fi
    else
        out=$(apt-get install opsstack-tools -y 2>&1)
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

# Get OpsStack endpoint
# Default value
ENDPOINT="https://opsstack.chinanetcloud.com"

echo ""
echo "Please enter OpsStack URL [Default: ${ENDPOINT}]"
read -p "Input: " ENDPOINT_INPUT
if [[ ! -z "$ENDPOINT_INPUT" ]]; then
    ENDPOINT=${ENDPOINT_INPUT}
fi
echo ""


# Execute opsstack-configure
opsstack-configure --opsstack-host ${ENDPOINT}
RES=$?

# Execute opsstack-install only if opsstack-configure exit with 0
if [[ "${RES}" -eq "0" ]]; then
    echo ""
    msg "Configuration complete"
    echo ""
    msg "Executing opsstack-install to add monitoring, collectors, syslog, nctop"
    echo ""
    # Execute opsstack-install
    opsstack-install
    RES=$?
    if [[ "${RES}" -eq "0" ]]; then
        echo ""
        msg "OpsStack installation finished"
        exit 0
    else
        msg_err
        error "Error running opsstack-install. Please try again or check documentation"
        exit ${RES}
    fi
else
    msg_err
    error "Error running opsstack-configure. Please try again or check documentation"
    exit ${RES}
fi
