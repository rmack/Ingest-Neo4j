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

function stopMazerunner
{
   ######################################## 
   # Get each Mazerunner container ID
   app_graphdb_1=`docker ps | grep  app_graphdb_1 | awk '{print $1}'`
   app_mazerunner_1=`docker ps | grep  app_mazerunner_1 | awk '{print $1}'`
   app_hdfs_1=`docker ps | grep  app_hdfs_1 | awk '{print $1}'`
   
   ########################################
   # Stop each Mazerunner container
   echo 
   echo "*****                  STOP                             *****"
   echo "***** Note this might take some time, please be patient *****"
   echo 
   docker stop $app_graphdb_1 $app_mazerunner_1 $app_hdfs_1
}

function startMazerunner
{
   ########################################
   # Start Mazerunner
   echo 
   echo "*****                  START                            *****"
   echo "***** Note this might take some time, please be patient *****"
   echo 
   docker run  -v /var/run/docker.sock:/var/run/docker.sock -ti kbastani/spark-neo4j up -d
   docker ps
}

function checkRunning
{
   runnning=0

   ########################################
   # Get each of the Docker container status required for Mazerunner to run
   neo4j=`docker ps | grep -c docker-neo4j`
   mazerunner=`docker ps | grep -c neo4j-graph-analytics`
   habase=`docker ps | grep -c hadoop-docker`

   if [ "$neo4j" = 1 ] && [ "$mazerunner" = 1 ] && [ "$habase" = 1 ]; then
      running=1
   fi
}

###########################################################################
# Main
###########################################################################
if [ "$1" = "stop" ]; then
   checkRunning
   if [ "$running" == 1 ]; then
      stopMazerunner
   else
      echo "Mazerunner is not running..."
   fi
else
   checkRunning
   if [ "$running" == 1 ]; then
      stopMazerunner
   fi
   startMazerunner
fi

exit 0

#EOF
