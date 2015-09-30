#!/usr/bin/perl
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

package ingest;
use strict;
use warnings;
use JSON qw( decode_json );
# UPDATE - Add debug
#use Data::Dumper; # Debug
###########################################################################
#
# Purpose: The purpose of this script is to break down known log files
#          into ingestable data for Neo4j.
#
# NOTE:    It is intended to have all (multi-type) log data within one
#          directory and this script will prase and process each known
#          type of log data 
#
###########################################################################

# Globals
my %model_hash = ();
my $erro = "";
my $info = "";
my $warn = "";
my $debu = "";
my $data = "";
my $model = "";
my $httpmonOutputFile = "";
my $httpmonCQLOutputFile = "";
my $httpmon_head = 0;
my %duplicates = ();

# To keep track of errors in which to stop the process
my $error = 0;

# Transition dir for CQL and CSV files pass by argument or default to tmp/ 
my $transitionDir = "tmp/";

# UPDATE - Maybe pass this in or set as a global static variable?
# The maximum number of CSV lines per file to ingest
my $fileCount = 5000;

# Grab from config? Static coded for now.
my @fileTypes = ( 'ufwallow', 'ufwblock' );

########################################
# Check command line args
my $num_args = $#ARGV + 1;
if ( $num_args < 2 )
{
   print "\nUsage: $0 <RAW data directory> <Model file directory>\n";
   print "Example:\n";
   print "   $0 ../data ../model ../tmp\n";

   exit;
}
else
{
   &main();
}


###########################################################################
# main - main
###########################################################################
sub main
{
   &init();
   &readModelSchemas();
   &processRawData();
   &done(0);
}


###########################################################################
# init - setup to run script
###########################################################################
sub init
{
   ########################################
   # Global variables
   $data  = $ARGV[0];
   $model = $ARGV[1];
   $transitionDir  = $ARGV[2];
   %duplicates = ( 'no'  => 'MERGE',
                   'yes' => 'CREATE' );

   $warn = "***** WARNING :";
   $info = "***** INFO    :";
   $erro = "***** ERROR   :";
   $debu = "***** DEBUG   :";

   # Make the holding directory
   `mkdir $transitionDir > /dev/null 2>&1`;
}


###########################################################################
# done - finalize script status = 0 = success; status = 1 = failure
###########################################################################
sub done
{
   my $status = $_[0];
   close ( CSV );
   close ( CQL );
   exit $status;
}

 
###########################################################################
# debug - print stdout arg0 = __LINE__; arg1 = info; arg2 = print string
###########################################################################
sub debug
{
   my @arguments = @_;

   print "$debu Line: $arguments[0] : $arguments[1] : $arguments[2] \n";
}


###########################################################################
# processRawData - This method will take RAW log files and generate CSV files
###########################################################################
sub processRawData
{
   # Increament for each new file I.e. filename<1>.csv .. filename<n>.csv 
   my $newFileCount = 0;

   # UPDATE - Maybe pass this in or set as a global static variable?
   # Increament for each new file I.e. filename<1>.csv .. filename<n>.csv 
   my $fileCounter = 0;

   # If RAW data log files are split into multiple files track when to 
   # bump fileCounter
   my $trackFileCount = 0;

   # The RAW data log files directory
   my $rawDataDir = $ARGV[0];

   # The model name for accessing the model template information
   my $model_key        = 'invalid';

   # The RAW data log columns to parse as there is seldom a 1 to 1
   # mapping of RAW data log columns to final CSV columns
   my @raw        = ();

   # Start processing each RAW data log file
   # Log files must end in ".log"
   for my $file ( glob( "$rawDataDir/*.log" ))
   {
      print "$info Parsing and formating $file into valid CSV & CQL files...\n";

      open ( RAW, $file ) || die "Can't open $file: $!\n";

      # Grab the model template given the name of the RAW data log filename
      $error = 1;
      for my $fileType ( @fileTypes )
      {
         # Make sure the RAW data log filename exists
         if ( $file =~ /$fileType/i )
         {
            $model_key = $fileType;
            $error = 0;

            if ( ! $model_hash{$model_key} )
            {
                # If there was an issue with the model then go to next file to process
                $error = 2;
                print "$erro $file doesn't have a model [$model_key] template defined\n";
                last;
            }
         }
      }

      # Check to make sure the filename exists
      if ( $error == 1 )
      {
          # If there was an issue with the filename then go to next file to process
          print "$erro $file doesn't have a filename matching known RAW file types\n";
          next;
      }
      elsif ( $error == 2 )
      {
         # Do not process any further no model template
         next;
      }

      # Grab each Column data structure defeind within the model template
      my @columns = @{ $model_hash{$model_key}->{columns} };

      # Each RAW data log line will be broken down first by a 
      # primary seperator, this is most commonly a space; " ".
      my $primarySeperator = "";
      if ( $model_hash{$model_key}->{primarySeperator} eq 'space' )
      {
         # Due to Perl not being able to read a " " out of JSON.
         # The key word space is used instead.
         $primarySeperator = " ";
      }
      else
      {
         # If 'space' isn't used grab the actual value
         $primarySeperator = $model_hash{$model_key}->{primarySeperator};
      }

      # Create the filename for the first time.
      # Two new files will be generated with converted data based on
      # the amount of rows to put in each new file. $fileCounter and $newFileCount
      my $csvFilename = $model_key . $fileCounter . ".csv";
      my $csvFile = ">" . $transitionDir . "/" . $csvFilename;
      my $cqlFile = ">" . $transitionDir . "/" . $model_key . $fileCounter . ".cql";

      # Open the files for the first time.
      # Open the files for the first time 
      # Open the pair of files associated with ingesting data into Neo4j
      open ( CSV, $csvFile ) || die "Can't open $csvFile: $!\n";
      open ( CQL, $cqlFile ) || die "Can't open $cqlFile: $!\n";

      # Create the header for each new CQL file for the first time
      # Create the header for each new CQL file 
      print CQL &CQLIngestHeader( $csvFilename );

      # Create the CQL body for each new CQL file for the first time
      # Create the CQL body for each new CQL file 
      print CQL &CQLIngestBody( $model_hash{$model_key} );

      # This section creates the header
      my $header = "";
      for my $column ( @columns )
      {
         # Check for the last column
         if ( $columns[$#columns] eq $column )
         {
            # Each CSV requires a header for Neo4j parsing
            $header .= '"' . $column->{name} . '"';
         }
         else
         {
            # Each CSV requires a header for Neo4j parsing
            $header .= '"' . $column->{name} . '",';
         }
      }

      # Print the CSV column header for the first time 
      print CSV $header . "\n";

      # Start reading the RAW data log file for parsing
      while (<RAW>)
      {
         # If we have reached the total amount of rows for each new file
         if ( $newFileCount == $fileCount )
         {
            # Close the CSV file
            close ( CSV );
            # Close the CQL file
            close( CQL );

            # Two new files will be generated with converted data based on
            # the amount of rows to put in each new file. $newFileCount
            $csvFilename = $model_key . $fileCounter . ".csv";
            $csvFile = ">" . $transitionDir . "/" . $csvFilename;
            $cqlFile = ">" . $transitionDir . "/" . $model_key . $fileCounter . ".cql";

            # Open the pair of files associated with ingesting data into Neo4j
            open ( CSV, $csvFile ) || die "Can't open $csvFile: $!\n";
            open ( CQL, $cqlFile ) || die "Can't open $cqlFile: $!\n";

            # Print the CSV column header for each new file
            print CSV $header . "\n";

            # Create the header for each new CQL file 
            print CQL &CQLIngestHeader( $csvFilename );

            # Create the CQL body for each new CQL file 
            print CQL &CQLIngestBody( $model_hash{$model_key} );

            $newFileCount=0;
            # Keep track of the total number of files to 
            # process within Mazerunner per RAW file breakdown/split
            $fileCounter++;

            # No reason to bump fileCounter again due to file splitting
            $trackFileCount = 1;
         }

         # Start processing each RAW data log file row
         chomp( $_ );
         my $line = $_;

         # If the primary seperator is a space fix any column spaces
         if ( $primarySeperator eq " " )
         {
            # UPDATE - Currently this is hard coded to fix space only
            # Maybe this should be fixed to include any:
            # Speacial characters for the primary seperator; encapsulating
            # characters for a column
            if ( $model_hash{$model_key}->{encapsulator} )
            {
               $line = &fixSpaces( $_, $model_hash{$model_key}->{encapsulator}  );
            }
         }

         # Grab each RAW data log row column for parsing
         @raw = split(/$primarySeperator/, $line );

# UPDATE - Add debug
# For debug only
#for my $tmp ( @raw )
#{
#   print "RAW Column: [$tmp]\n";
#}

         my $csvLine = "";
         for my $column ( @columns )
         {
            my $newColumn = "";

            # If the raw column is more than 1 defined column
            # seperate the RAW column into the real column
            if ( $column->{seperator} )
            {
               my $delimiter = $column->{seperator};
               # Check for special charaters
               if ( $column->{seperator} eq "|" )
               {
                  $delimiter = quotemeta($column->{seperator});
               }

               my @tmpColumns = ();
               @tmpColumns = split( /$delimiter/, $raw[$column->{raw}] );
               $newColumn = $tmpColumns[$column->{index}];
            }
            else
            {
               $newColumn = $raw[$column->{raw}];
            }

# UPDATE - Add debug
# For debug only
#print "New Column: [" . $newColumn . "]\n";

            # UPDATE - These need to be automated tmp solution
            # '"' is the default encapsulation of columns character
            # '__SPACE__' is the default replacement value for spaces 
            $newColumn =~ s/"//g;
            $newColumn =~ s/__SPACE__/ /g;

            # Check for the last column
            if ( $columns[$#columns] eq $column )
            {
               # Last new CSV column for this row
               $csvLine .= '"' . $newColumn . '"';
            }
            else
            {
               # Each new CSV column for this row
               $csvLine .= '"' . $newColumn . '",';
            }
         }

         print CSV "$csvLine\n";

         # decremeant the line count
         $newFileCount++;
      }

      if ( $trackFileCount == 0 )
      {
         # Keep track of the total number of files to 
         # process within Mazerunner per RAW file
         $fileCounter++;
      }
      else
      {
         # Reset as the counter was bumped due to file splitting
         $trackFileCount = 0;
      }

      # Close the CSV file
      close ( CSV );
      # Close the CQL file
      close( CQL );
      # Close the RAW data log file 
      close( RAW );

   }

   print "$info There are [$fileCounter] csv files to process...\n";
}


###########################################################################
# readModelSchemas - pull in each Model schema for the purpose of generating
#                    CQLIngestFiles.
##########################################################################
sub readModelSchemas
{
   # Global Hash of JSON models
#   %model_hash = ();

   # sub variables
   my $text = "";
   my $data = "";

   # Make sure the model dir path provided exists
   if ( ! -d $model )
   {
      print "$erro Model directory location invalid \n";
      print "$info $model                           \n";
      print "Exiting                                \n";
      &done(1);
   }

   # Read each JSON model file which must end with ".model.json"
   foreach my $file (glob("$model/*.model.json"))
   {
       print "$info attempting to read $file \n";
      # Reset text and data for each file
      $text = "";
      $data = "";

      # Open the model file to gather info to create CQL
      open ( MODEL, $file ) || die "Can't open $file: $!\n";

      # Append on lines in the file to $text
      while (<MODEL>)
      {
         chomp( $_ );
         $text .= $_;
      }

      close( MODEL );

      # To save memory remove all white space
      $text =~ s/ *//g;

# UPDATE - Add debug
# Add ability to debug here for json files
# Give directions with vim on how to get the the position in the line.
#print "$text";
      # Decode text as JSON data
      $data = decode_json( $text );

# UPDATE - Add debug
# Used for debugging decoded JSON data after decode
# Dumper($data);

      # Store each JSON model per model type
      $model_hash{ $data->{model} } = $data;
   }
}


###########################################################################
# fixSpaces - If RAW data uses " to encapsulate spaces then this
#             function will replace " " with __SPACE__
# @parrameter RAW line from RAW data log
# @parrameter encapsulator - e.g. '"', '|', etc... 
###########################################################################
sub fixSpaces
{
   my $line = $_[0];
   my $encapsulator = $_[1];
   my $fakeSpace = "__SPACE__";

   chomp($line);

   my @chars = split( "", $line );
   my $newLine = "";

   my $start = 0;
   for my $char ( @chars )
   {
      if ( $encapsulator eq "|" )
      {
         if ( $char eq "|" )
         {
            $start = 1;
         }
      }

      if ( $encapsulator eq 'quotes' )
      {
         if ( $char eq '"' )
         {
             if ( $start == 0 )
             {
                $start = 1;
             }
             elsif ( $start == 1 )
             {
                $start = 0;
             }
         }
      }

      if ( $start == 1 )
      {
         if ( $char eq " " )
         {
            $char =~ s/ /$fakeSpace/;
         }
      }
      $newLine .= $char;
   }

   return $newLine;
}

##########################################################################
# CQLIngestHeader - get the CQL ingest header for each file to ingest
###########################################################################
sub CQLIngestHeader
{
   my $filename = $_[0];
   my $header = "USING PERIODIC COMMIT 1000\n" .
                "LOAD CSV WITH HEADERS FROM 'file:///tmp/$filename' AS line\n";
   return $header;
}


##########################################################################
# CQLIngestBody - get the CQL ingest body for each model
# @parameter - Ref JSON model - $model_hash{$key}
# @return - Created CQL Body for passed in JSON model
###########################################################################
sub CQLIngestBody
{
   my $body = "";
   my $model = $_[0];
   my @nodes = ();
   my @relationships = ();

   # Generate reach node CQL statement
   @nodes = @{$model->{nodes}};
   for my $node ( @nodes )
   {
      # Begin Node creation
      $body .= $duplicates{$node->{duplicates}};
      $body .= " ( $node->{alias}:";

      # Begin label creation
      my @labels = @{$node->{labels}};
      for my $label ( @labels )
      {
         # Last label finalize
         if ( $labels[$#labels] eq $label )
         {
            $body .= "$label";
         }
         else
         {
            $body .= "$label:";
         }
      }

      # Begin property creation
      # Make sure properties exist for the node
      if ( $node->{properties} )
      {
         my @properties = @{$node->{properties}};
         if ( $#properties > -1 )
         {
            $body .= " {\n";
         }
         for my $property ( @properties )
         {

            my $outProperty;
            my $ifStaticProperty = 0;

            # If a property is a hash then there are static values
            # A static value will not come from the log file user gnerated
            if (  ref($property) eq 'HASH' )
            {
               # The property value is designated with the key word "static"
               my @staticProperties = @{$property->{static}};
               for my $static_ref ( @staticProperties )
               {
                   # Make sure we do not add the reference as a property
                   $ifStaticProperty = 1;

                   # Grab the hash of static values to set as properties
                   my %static = %$static_ref;
                   for my $key ( keys %static )
                   {
                       # Set each static value within the CQL statement
                       $body .= "   $key: '$static{$key}'" . ",\n";
                   }
               }
            }
            else
            {
               $ifStaticProperty = 0;
               $outProperty = $property;
            }

            # Take any propertry value and convert the name
            if ( $node->{$property} )
            {
               $outProperty = $node->{$property};
            }

            # Last property finalize
            if ( $ifStaticProperty == 0 )
            {
               if ( $properties[$#properties] eq $property )
               {
                  $body .= "   $outProperty: line.$property\n" . "}";
               }
               else
               {
                  $body .= "   $outProperty: line.$property" . ",\n";
               }
            }
         }
      }

      # End Node
      $body .= ")\n";
   }

   # Generate reach relationship CQL statement
   @relationships = @{$model->{relationships}};
   for my $relationship ( @relationships )
   {
      # Begin Relationship creation
      $body .= $duplicates{$relationship->{duplicates}};
      $body .= " (" . $relationship->{from} . ")-[" . $relationship->{alias} . ":";

      # Begin label creation
      $body .= $relationship->{label};

      # Begin property creation
      # Make sure properties exist for the relationship
      if ( $relationship->{properties} )
      {
         my @properties = @{$relationship->{properties}};
         if ($#properties > -1 )
         {
            $body .= " {\n";
         }
         for my $property ( @properties )
         {
            my $outProperty = $property;

            if ( $relationship->{$property} )
            {
               $outProperty = $relationship->{$property};
            }

            # Last property finalize
            if ( $properties[$#properties] eq $property )
            {
               $body .= "   $outProperty: line.$property\n" . "}";
            }
            else
            {
               $body .= "   $outProperty: line.$property" . ",\n";
            }
         }
      }

      # End Relationship
      $body .= "]->(" . $relationship->{to} . ")\n";
   }

   # Generate the return statement
   # There must exist nodes
   if ( $#nodes > -1 )
   {
      $body .= "RETURN ";
      for my $node ( @nodes )
      {
         # Last node finalize
         if ( $nodes[$#nodes] eq $node )
         {
            $body .= "$node->{alias}";
         }
         else
         {
            $body .= "$node->{alias},";
         }
      }

      # There must exist relationships
      if ( $#relationships > -1 )
      {
         # Because there are relationships add a ","
         $body .= ",";

         for my $relationship ( @relationships )
         {
            # Last relationship finalize
            if ( $relationships[$#relationships] eq $relationship )
            {
               $body .= "$relationship->{alias};";
            }
            else
            {
               $body .= "$relationship->{alias},";
            }
         }
      }
      else
      {
         $body .= ";";
      }
   }

   return $body;
}
#EOF
