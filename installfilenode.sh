#!/bin/bash
logging=false


#If you turn logging on, be aware your filenode.log may contain your pool access key!

set -eu -o pipefail # fail on error , debug all lines

LOG_LOCATION=/root/
node_folder="copi-node"

if [[ $logging == true ]];
then
echo "Logging turned on"
exec > >(tee -i $LOG_LOCATION/filenode.log)
exec 2>&1
fi

apt-get update -y && apt-get upgrade -y

# For output readability
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

shopt -s globstar dotglob

cat << "MENUEOF"

 ██████╗ ██████╗ ██████╗ ██╗                                      
██╔════╝██╔═══██╗██╔══██╗██║                                      
██║     ██║   ██║██████╔╝██║                                      
██║     ██║   ██║██╔═══╝ ██║                                      
╚██████╗╚██████╔╝██║     ██║                                      
 ╚═════╝ ╚═════╝ ╚═╝     ╚═╝                                      
                                                                  
███████╗██╗██╗     ███████╗    ███╗   ██╗ ██████╗ ██████╗ ███████╗
██╔════╝██║██║     ██╔════╝    ████╗  ██║██╔═══██╗██╔══██╗██╔════╝
█████╗  ██║██║     █████╗      ██╔██╗ ██║██║   ██║██║  ██║█████╗  
██╔══╝  ██║██║     ██╔══╝      ██║╚██╗██║██║   ██║██║  ██║██╔══╝  
██║     ██║███████╗███████╗    ██║ ╚████║╚██████╔╝██████╔╝███████╗
╚═╝     ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝
                                                                  

███╗   ███╗███████╗███╗   ██╗██╗   ██╗
████╗ ████║██╔════╝████╗  ██║██║   ██║
██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║
██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║
██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝
╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

MENUEOF

PS3='Please choose what type of node you are installing today.  File node is only available for now. Please write the number of the menu item and press enter: '
filenode="Install a COPI File Node"
testnet="Other options in the future"
cancelit="Cancel"
options=("$filenode" "$cancelit")
asktorestart=0
select opt in "${options[@]}"
do
    case $opt in
        "$filenode")
        action="filenode"
        echo "You chose a file node install"
        sleep 1
         break
            ;;
        "$testnet")
            echo "You chose an option not live yet"
        action="testnet"
        sleep 1
        break
            ;;
       "$cancelit")
            echo "${RED}You chose to cancel${COLOR_RESET}"
        action="cancel"
        exit 1
break
            ;;
        "Quit")
            exit 1
break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done


echo "Welcome to the COPI File Node Installer . We will begin to ask you a series of questions.  Please have to hand:"
echo "✅ Your SSH Port No"
echo "✅ Your Ubuntu Username"
echo "✅ Your Pool Access Key"




read -n 1 -r -s -p $'Press enter to begin...\n'

read -p "What is your ssh port number (likely 22 if you do not know)?: " portno
read -p "What is your ubuntu username (use copi if unsure as it will be created fresh. Do not use root) ?: " username
read -p "What is your pool access key? Please enter or paste it in now:" PoolAccessKey


if [[ $portno == "" ]] || [[ $username == "" ]] || [[ $PoolAccessKey == "" ]];
then
echo "${RED}Some details were not provided.  Script is now exiting.  Please run again and provide answers to all of the questions${COLOR_RESET}"
exit 1
fi


if [[ $PoolAccessKey = "" ]];
then
echo "Pool access key was not provided. Please run again and provide answers to all of the questions"
exit 1
fi


#########################################
# Create $username user if needed (Recently Moved)
#########################################

if id "$username" >/dev/null 2>&1; then
        echo "user exists"
else
        echo "user does not exist...creating"
        adduser --gecos "" --disabled-password $username
        adduser $username sudo

fi


# Get Server IP
exec 3<>/dev/tcp/ipv4.icanhazip.com/80
echo -e 'GET / HTTP/1.0\r\nhost: ipv4.icanhazip.com\r\n\r' >&3
while read i
do
 [ "$i" ] && serverip="$i"
done <&3

serverurl=http://$servername:8001/
healthurl=http://$servername:8001/health


apt-get update -y && sudo apt-get upgrade -y

echo "Installing prereqs..."
apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


ubuntuvers=$(lsb_release -rs)
echo "Ubuntu version $ubuntuvers detected"


ufw limit $portno
ufw allow 8001/tcp
ufw --force enable

chown -R $username: /home/$username/$node_folder/
cd /home/$username/$node_folder/


logging_file_name="";

if [[ $action == "filenode" ]];
then

cat <<EOF-SETUP >/home/$username/$node_folder/docker-compose.yml
name: cornucopias
services:
    pool-server:
        image: public.ecr.aws/cornucopias/nodes/pool-server:latest
        ports:
          - "8001:8001"
        restart: unless-stopped # if you want to manually start the pool server replace “unless-stopped” with “no”
        environment:
            FILENODES_POOL_ACCESS_KEY: $PoolAccessKey
            FILENODES_POOL_PUBLIC_PORT: 8001
        volumes:
          - /home/$username/$node_folder/cache:/cache
EOF-SETUP

fi


echo "Applying chgrp and chown to docker compose"
chown $username /home/$username/$node_folder/docker-compose.yml
chgrp $username /home/$username/$node_folder/docker-compose.yml

read -n 1 -r -s -p $'Press enter to start the docker compose up -d in /home/$username/$node_folder/ ”...\n'
cd /home/$username/$node_folder/
docker compose up -d




while true; do
    STATUS=$(curl -s "$healthurl

    if [[ "$STATUS" == "Ok" ]]; then
          echo "${GREEN}Node is healthy! You're done! Now why not download uptimerobot app and let it watch KEYWORD "Ok" at $healthurl so you can be notified when it is offline or failing."${COLOR_RESET}"
        break

    else
     echo "Waiting to check health in 5 seconds..."
    fi

    sleep 5  # Wait for 5 seconds before checking again
done






