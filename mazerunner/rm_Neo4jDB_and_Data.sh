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
# Purpose: Remove the Neo4j Graph populated database.
#
# NOTES:   This script uses docker commands to remove the database
#
###########################################################################

########################################
# This script must run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check to make sure Mazerunner is running before running script
./running.sh silent
if [ "$?" = "1" ]; then
   echo
   echo "***** Mazerunner must be running!" 
   echo

   exit 1
fi

echo
echo "***** WARNING WARNING WARNING WARNING WARNING *****"
echo "      This will delete the Neo4j Database          "
echo
echo "      /opt/data/graph.db                           "
echo
echo "+++++ PROCEED?                                     "
read -p "Enter <Y|N>? " input
if [ "$input" == "Y" -o "$input" == "y" ]; then

   # Execute the following within the Neo4j docker container
   docker exec -i app_graphdb_1 rm -rf /opt/data/graph.db
   docker exec -i app_graphdb_1 rm -rf /tmp/*
   `./running.sh silent`
   if [ "$?" = "0" ]; then
      echo
      echo "***** DELETED /opt/data/graph.db" 
      echo
      echo "***** Attempting to shutdown Mazerunner after database file removed!" 
      echo
      ./mazerunner.sh stop
   else
      echo
      echo "***** Mazerunner must be running!" 
      echo
   fi

else
   echo
   echo "***** CANCELED" 
   echo
fi


exit 0;
#EOF
