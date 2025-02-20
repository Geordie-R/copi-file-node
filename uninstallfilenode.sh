#!/bin/bash

# This will uninstall the filenode so that you can run the install again.
# Note this will remove the directory at /home/<yourusername>/filenode

read -p "What is your ubuntu username (its likely to be copi if you followed the default suggestion on the install) ?: " username
echo "Removing docker image that contains pool-server..."
# Get Container ID
container_id=$(docker ps | grep "pool-server" | awk '{print $1}')

if [ -n "$container_id" ]; then
    echo "Stopping container: $container_id"
    docker stop "$container_id"
    
    echo "Removing container: $container_id"
    docker rm "$container_id"
else
    echo "No running container found for pool-server."
fi


echo "Removing /home/$username/filenode"
rm -R /home/$username/filenode 2> /dev/null

