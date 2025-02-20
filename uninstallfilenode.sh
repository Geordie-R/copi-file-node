#!/bin/bash

#This will uninstall the filenode so that you can run the install again.
# Note this will remove the directory at /home/<yourusername>/filenode

read -p "What is your ubuntu username (its likely to be copi if you followed the default suggestion on the install) ?: " username
echo "Removing docker image that contains pool-server..."
docker images | grep "pool-server" | awk '{print $3}' | xargs docker rmi
echo "Removing /home/$username/filenode"
rm -R /home/$username/filenode 2> /dev/null

