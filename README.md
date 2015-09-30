# Automate Ingest Neo4j  
  
This project was originally intended to research and investigate an ad-hoc 
approach to dynamically modify/update graph based data models through ingesting 
RAW data logs. The [Mazerunner](https://github.com/kbastani/neo4j-mazerunner) project was selected as a quick framework for 
being able to investigate model changes. The framework enables investigations 
with both graph based queries and graph based analytics.

The project hasn't been fully realized, but an approach (Proof-of-concept) has 
been successfully implemented demonstrating an ad-hoc approach enabling a way 
to quickly update a graph based model which can then re-ingest RAW data logs 
into Neo-4j. In addition, this adhoc approach also demonstrates a method for 
adding new RAW data log types and creating new graph based models from this data. 
This means parsing RAW data logs and generating CSV files.
  
### Requirements  
* Debain based OS (Ubuntu, Mint, etc...)
* Docker version > 1.3
* Perl
* CPAN JSON module
* bash
* Sudo or admin privledges
* Access to the Mazerunner docker images (network connection)
  

### List of scripts  
#### Docker  
* **docker/installDockerUbuntu.sh** - Installs and configures Docker for Debian based systems (Ubuntu)

#### Mazerunner  
* **mazerunner/mazerunner.sh** - Starts and stops mazerunner parameter (start | stop)
* **mazerunner/running.sh** - Checks if mazerunner is running optional parameter (silent)
* **mazerunner/pull_GraphDB_From_Docker.sh** - Pulls the Neo4j graph database from within the Docker container
* **mazerunner/push_Neo4j_DB_To_Docker.sh** - Pushes the Neo4j graph database back into the Docker container
* **mazerunner/push_Neo4j_DB_To_Docker.sh** - Pushes the Neo4j graph database back into the Docker container
* **mazerunner/rm_Neo4jDB_and_Data.sh** - Removes the Neo4j graph.db database and tmp ingest data to start over
* **mazerunner/ingest_data_into_mazerunner.sh** - Runs everything within the repo to parse/convert and ingest data into Neo4j

#### Ingest  
* **ingest/ingest.sh** - Script pushed into Docker to ingest generated CSV and CQL files into Neo4j
* **ingest/test.sh** - Test the generate_ingest_Files.pl script only
* **ingest/generate_ingest_Files.pl** - Generate CSV and CQL files used to ingest data into Neo4j
   
### Ingest  
Ingest requires any log file to be parsed and converted into a CSV file format. 
To complete this task a JSON configuration file is used to determine how to parse 
and process RAW data logs and convert them into a formatted CSV file. The same 
JSON configuraiton file is used for generating a Neo4j CQL file for each CSV file 
generated.
  
#### Ingest Requirements
This section covers general requirments for ingesting RAW data logs.
  
* The RAW data log filename must have a portion of its name the same as the model JSON config file.
  * E.g. ./data/**ufw**_1.log ./model/**ufw**.model.json
* The RAW data log rows must currently have all of the same columns types
  * <rwo> - column1 column2 column3 ... etc...
* Sub columns are allowed up to a deapth of 2. I will potentially modify to allow any deapth.
  * SRC=192.168.1.68 DST=255.255.255.255 - can be broken into IP only upon parsing for example
* User should have an understanding of the RAW data to do graph based modeling and parse the data
* Thre can only be one data encapsulator at the moment. E.g. "data data data", |data data data|, etc...
  * This will not work at the moment: (data data), [data data], {data data}, etc...

#### generate_ingest_Files.pl
This script processes all RAW data log files contained within the provided 
directory as a parameter on the command line. Process means parsing each file 
in the provided directory, formatting the CSV files, and genereating multiple 
CSV and CQL files to ingest into Neo4j using Neo4j's LOAD CSV mechinsim. 
This script requires three parameters which are ordered.

* **data** - the location of all data files to process
* **model** - the location of all of the JSON model configuration files
* **tmp** - a temporary location to generate all CSV and CQL files

##### Example
./generate_ingest_Files.pl ../data ../model ./tmp

##### Test generate_ingest_Files.pl
* Generate a model.json file
* Put the model.json file into the model dir
* Put the RAW data log file into the data dir
* cd ingest
* ./generate_ingest_Files.pl ../data ../model ./tmp
* Check for errors
* cd ./tmp - look at CSV and CQL files for issues

### Models
Model templates enable a user to dynamically change their graph model prior
to ingesting data. The model templates are formatted in JSON, and each model 
must end with .model.json. If there are different models and different RAW data 
logs files then they can all be placed within the same directories. Specifically 
if you want to process different graph domains given different RAW data logs 
then all of the models need to be placed in the same directory and all of the 
RAW data logs need to be placed inthe same directory. The example above shows 
these directories as ../data and ../model. The model.json files include to 
major structures.

* Model - The graph based model representation in JSON
* Parse - The configuration to parse a RAW data log into a CSV format

#### Model template

A model template uses JSON to define a single graph domain model and single way 
defining how to parse a RAW data log file.
* Each column within a single row is meant to represent a property value
* A column can be included or excluded as a part of the model
* Node labels are user defined and static
* Relationship labels are user defined and static
* Properties can be dynamic or static
  * Dynamic - If a column name is used within the Properties JSON array
  * Static - If a key value array is defined within the properties JSON array

The model doesn't currently allow for all Neo4j ingest capabilities, but it 
does allow for enough capabilities to build out Nodes, Relathionships, and 
properties. For example it doesn't allow conversions on data such as converting
a "1" to an integer. All values ingested are ingested as strings.

##### Domain Model Key Values
* **model** - Key word defining the name of the domain model
* **nodes** - Key word defining an array of nodes to ingest
* **relationships** - Key word defining an array of relationships to ingest

##### Node Key Values
* **alias** - The alias to use with this node for the ingest CQL e.g. "a", "b"...
* **labels** - The labels to use with this node there can be more than 1 (array)
* **duplicates** - Yes - use CREATE; No - use MERGE
* **properties** - An array of properties which need to match the RAW data log column names
* **ColumnName** - Any property name that you would like to change to another name
* **static** - An array or key value pair representing static user defined properties

##### Relationship Key Values
* **alias** - The alias to use with this relationship for the ingest CQL e.g. "a", "b"...
* **labels** - The label to use with this relationship
* **duplicates** - Yes - use CREATE; No - use MERGE
* **from** - The alias node given direction from which the relationship is **coming from**
* **to** - The alias node given direction from which the relationship is **going to**
* **properties** - An array of properties which need to match the RAW data log column names
* **ColumnName** - Any property name that you would like to change to another name

### Run  
To run you will need to do the following  

#### Run once  
This is intended to install docker if it hasn't been installed before. 
This script should only need to be run once.  
* docker/installDockerUbuntu.sh # Should work on a debain based system  
* Perl CPAN JSON
  * wget http://search.cpan.org/CPAN/authors/id/M/MA/MAKAMAKA/JSON-2.90.tar.gz
  * tar xvfz JSON-2.90.tar.gz
  * cd JSON-2.90
  * perl Makefile.PL
  * make
  * sudo make install
  
#### Run ingest data into Neo4j  
A RAW data log will need to be modeled. Then place the model.json file in the 
./model directory. Place the RAW data log into the ./data directory. 

**sudo ./mazerunner/ingest_data_into_mazerunner.sh ./data ./model ./tmp**

This will start Mazerunner within three joined Docker Containers. Specifically 
this means all of the needed components for Mazerunner will be donwloaded and 
will start up. This takes a little time the first time it is run. It might take 
up to 30 minutes, so grab a snack after you kick the script off.

##### The following happens after running the script
* Make the ./tmp directory if it wasn't already created
* Check to make sure mazerunner is running, otherwise start it
* Wait 30 seconds for Mazerunner to start
* Use the ./data directory for all RAW data logs
* Use the ./model directory for all domain specific models
* Parse the RAW data logs and generate CSV files
* Create a CQL file for each CSB file generated
* Push all CQL and CSV files into the docker container /tmp
* Run a script called ingest.sh within the docker container

##### View the data
* http://localhost:7474 - Access Neo4j web interface
* Graph analysis jobs are started by accessing the following endpoint:
  * **Generic** http://localhost:7474/service/mazerunner/analysis/{analysis}/{relationship_type}