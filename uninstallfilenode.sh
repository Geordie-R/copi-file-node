#!/bin/bash

# This will uninstall the filenode so that you can run the install again.
# Note this will remove the directory at /home/<yourusername>/filenode

read -p "What is your ubuntu username (Leave it empty to just use $USER) ?: " username

if [[ $username == "" ]] || [ -z "$username" ];
then
  username=$USER
fi

user_home=$(eval echo "~$username")

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

echo "Removing $user_home/filenode"
rm -R $user_home/filenode 2> /dev/null
echo "Script Complete"
