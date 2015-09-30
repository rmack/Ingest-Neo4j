#!/bin/bash

########################################
# This script must run as root
if [ "$(id -u)" != "0" ]; then
   if [ "$silent" != 1 ]; then
      echo "This script must be run as root" 1>&2
   fi
   exit 1
fi

docker exec -it app_graphdb_1 /bin/bash
