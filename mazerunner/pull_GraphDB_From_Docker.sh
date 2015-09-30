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
# Purpose: Grab the Neo4j database from the Neo4j docker container 
#
# NOTES:   This script uses docker commands to grab the database.
#          The database files are tar and then gzip into a single file.
#
###########################################################################

########################################
# This script must run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check to make sure Mazerunner is running before running script
running.sh silent
if [ "$?" = "1" ]; then
   echo
   echo "***** Mazerunner must be running!" 
   echo

   exit 1
fi

echo
echo "***** WARNING WARNING WARNING WARNING WARNING  *****"
echo "      This will grab the Neo4j Database            "
echo
echo "***** MAKE SURE YOU ARE NOT ACTIVELY USING IT  *****"
echo
echo "      /opt/data/graph.db                           "
echo
echo "+++++ PROCEED?                                     "
read -p "Enter <Y|N>? " input
if [ "$input" == "Y" -o "$input" == "y" ]; then

   # Execute the following within the Neo4j docker container
   docker exec -i app_graphdb_1 rm -rf /tmp/graph.db.tar.gz
    # Tar graph.db dir only as if we cd to /opt/data
   docker exec -i app_graphdb_1 tar cvf /tmp/graph.db.tar -C /opt/data .
   docker exec -i app_graphdb_1 gzip /tmp/graph.db.tar 
   docker cp app_graphdb_1:/tmp/graph.db.tar.gz .
   docker exec -i app_graphdb_1 rm -rf /tmp/graph.db.tar.gz
   echo
   echo "***** EXPORTED graph.db.tar.gz" 
   echo
else
   echo
   echo "***** CANCELED" 
   echo
fi

exit 0;
#EOF
