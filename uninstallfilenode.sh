#!/bin/bash

# This will uninstall the filenode so that you can run the install again.
# Note this will remove the directory at /home/<yourusername>/filenode

read -p "What is your ubuntu username (it's likely to be copi or root) ?: " username

read -p "What is your container name? (it's likely to be COPNode1 if you accepted defaults on the install) ?: " ContainerName


echo "Removing docker image that contains pool-server..."
# Get Container ID

# Check if the container exists
if docker ps -a --format '{{.Names}}' | grep -w "$ContainerName" &> /dev/null; then
    echo "Container $ContainerName found. Removing it..."
    docker rm -f "$ContainerName"
else
    echo "Container $ContainerName not found."
fi

echo "Removing /home/$username/filenode"
rm -R /home/$username/filenode 2> /dev/null
echo "Script Complete"
