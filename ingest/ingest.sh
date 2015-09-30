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
# ingest.sh - This script will simply take each *.cql file and try to 
#             ingest the corrisponding CSV file into Neo4j.
#
# NOTE: This script is intended to be pushed inside a Neo4j Docker container
#       along with each *.cql and *.csv file from the data directory.
#
###########################################################################

########################################
# foreach file within /tmp which contains a .cql extension
for file in `ls /tmp/*.cql`; do
    echo "***** Neo4j ingest $file"
    echo "***** CMD: time neo4j-shell -file $file > $file"".log"
    time neo4j-shell -V -file $file > $file".log"
done

#EOF
