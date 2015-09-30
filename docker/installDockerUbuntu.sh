#!/bin/bash 
###########################################################################
# Copyright 2015 Russell T Mackler 
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
###########################################################################

########################################
# This script must run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

########################################
# Check to make sure the kernel is compatable with docker
kernel=`uname -r | gawk -F\. '{printf "%s.%s", $1, $2}'`
kernelCheck=`echo $kernel'>'3.11 | bc -l`

if [ "$kernelCheck" == "0" ]; then
   echo "kernel not compatible $kernel"
   echo "exiting..."
   exit 1
fi


########################################
# Update firewall via UFW
ufwStatus=`ufw status | grep Status: | gawk '{print $2}'`
if [ "$ufwStatus" == "active" ]; then
   # Check if DEFAULT_FORWARD_POLICY is set to "ACCEPT"
   DEFAULT_FORWARD_POLICY=`cat /etc/default/ufw | grep DEFAULT_FORWARD_POLICY | grep -c -i ACCEPT`
   if [ $DEFAULT_FORWARD_POLICY == "0"  ]; then
      echo "Modify /etc/default/ufw DEFAULT_FORWARD_POLICY=ACCEPT?"
      read -p "Enter <Y|N>? " input
      if [ "$input" == "Y" -o "$input" == "y" ]; then
         echo "Modifying /etc/default/ufw inline..."
         echo "Backup /etc/default/ufw.bak"
         sed -i.bak s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g /etc/default/ufw 
         echo "ufw reload..."
         ufw reload
         echo "Allow incoming connections on the Docker Port..."
         echo "ufw allow 2375/tcp..."
         ufw allow 2375/tcp
      fi
   fi
fi


########################################
# Install Docker and needed components
apt-get -q update && apt-get -q install cgroup-lite apparmor
wget -qO- https://get.docker.com/ | sh
docker -d &
docker version

#EOF

