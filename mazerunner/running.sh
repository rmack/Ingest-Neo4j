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

###########################################################################
#
# running.sh - This scripts checks to see if Mazerunner is running
#
# param  : silent - Turn off all echo; only return the status
#
# return : status 0 if everything is running
# return : status 1 if one of the 3 needed components are not running 
#
###########################################################################

if [ "$1" = 'silent' ]; then
   silent=1
else
   silent=0
fi

status=1

########################################
# This script must run as root
if [ "$(id -u)" != "0" ]; then
   if [ "$silent" != 1 ]; then
      echo "This script must be run as root" 1>&2
   fi
   exit 1
fi

########################################
# Get each of the Docker container status required for Mazerunner to run
neo4j=`docker ps | grep -c docker-neo4j`
mazerunner=`docker ps | grep -c neo4j-graph-analytics`
habase=`docker ps | grep -c hadoop-docker`

# Check if the Neo4j Docker Container is running
if [ "$neo4j" = 1 ]; then
   if [ "$silent" != 1 ]; then
      echo "***** Docker Neo4j is running..."
   fi
   status=0
else
   if [ "$silent" != 1 ]; then
      echo "***** Docker Neo4j stopped..."
   fi
fi

# Check if the Mazerunner Docker Container is running
if [ "$mazerunner" = 1 ]; then
   if [ "$silent" != 1 ]; then
      echo "***** Docker Mazerunner Orchestration is running..."
   fi

   # Neo4j must also be running
   if [ "$status" = 0 ]; then
      status=0
   fi
else
   status=1
   if [ "$silent" != 1 ]; then
      echo "***** Docker Mazerunner Orchestration stopped..."
   fi
fi

# Check if the HBase Docker Container is running
if [ "$habase" = 1 ]; then
   if [ "$silent" != 1 ]; then
      echo "***** Docker HBase running..."
   fi

   # Neo4j & Mazerunner Orchestration must also be running
   if [ "$status" = 0 ]; then
      status=0
   fi
else
   status=1
   if [ "$silent" != 1 ]; then
      echo "***** Docker HBase stopped..."
   fi
fi

exit $status

#EOF
