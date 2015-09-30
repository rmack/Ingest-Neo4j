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
# ingest_data_into_mazerunner.sh - This script will do the following
#
# 1. Start Mazerunner
# 2. Process all csv files within the data directory for ingest into neo4j
# 3. Push all files into the Neo4j Docker container 
# 4. Execute the ingest script to ingest all csv files within /tmp 
# 5. Cleanup all tmp files created from this test 
#
# NOTE: Point your broswer to http://localhost:7474 to view all imported
#       data
#
###########################################################################
########################################
# This script must run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Set the base directory for this script
baseDir=`pwd`

# All test work is pushed to tmp in the local dir
rm -rf tmp/* > /dev/null 2>&1
mkdir tmp > /dev/null 2>&1 

echo
echo "***** Start the Mazerunner application *****"
echo "      Neo4j Docker container                "
echo "      Hbase, Spark, GraphX                  "
echo "      Mazerunner orchestration              "
echo
`running.sh silent`
if [ "$?" = 1 ]; then
   mazerunner.sh start
   sleep 30
fi

echo
echo "***** Process the csv files            *****"
echo "      Format all csv files within data      "
echo "      Generate the CQL ingest files         "
echo
cd ../ingest
./generate_ingest_Files.pl ../data ../models $baseDir/tmp
cd $baseDir

echo
echo "***** Push all files into Neo4j Docker *****"
echo "      Copy ingest.sh into /tmp dir          "
echo "      Push all files within /tmp dir        "
echo
# Remove all old files for ingest out of /tmp within the docker container
docker exec -i app_graphdb_1 rm -rf /tmp/*
cp ../ingest/ingest.sh tmp/.
cd tmp
tar -cv * | docker exec -i app_graphdb_1 tar x -C /tmp
cd $baseDir

echo
echo "***** Exec ingest.sh within Docker     *****"
echo
docker exec -it app_graphdb_1 /bin/bash /tmp/ingest.sh

echo
echo "***** Cleanup                          *****"
echo "      rm -rf tmp                            "
echo
#rm -rf tmp

#EOF
