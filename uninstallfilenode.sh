#!/bin/bash

#This will uninstall the filenode so that you can run the install again.
# Note this will remove the directory at /home/<yourusername>/filenode

read -p "What is your ubuntu username (its likely to be copi if you followed the default suggestion on the install) ?: " username
rm -R /home/$username/filenode 2> /dev/null

