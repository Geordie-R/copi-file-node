#!/bin/bash
logging=false


#If you turn logging on, be aware your filenode.log may contain your pool access key!

set -eu -o pipefail # fail on error , debug all lines

LOG_LOCATION=/root/


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
        node_folder="filenode"
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


echo "💡 Note: If you need to copy and paste into terminal, you can paste by Ctrl + Shift + V or by using a right click"

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

function GetServerIP() {
    exec 3<>/dev/tcp/ipv4.icanhazip.com/80
    echo -e 'GET / HTTP/1.0\r\nhost: ipv4.icanhazip.com\r\n\r' >&3

    local serverip=""
    while read -r i; do
        [ "$i" ] && serverip="$i"
    done <&3

    echo "$serverip"
}

serverip=$(GetServerIP)

serverurl=http://$serverip:8001
healthurl=$serverurl/health


echo "Your health URL will be $healthurl"

apt-get update -y && sudo apt-get upgrade -y

echo "Installing prereqs..."
apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


ubuntuvers=$(lsb_release -rs)
echo "Ubuntu version $ubuntuvers detected"


ufw limit $portno
ufw allow 8001/tcp
ufw --force enable

mkdir -p /home/$username/$node_folder/

cacheurl="/home/$username/$node_folder/cache"


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
          - $cacheurl:/cache
EOF-SETUP

fi


echo "Applying chgrp and chown to docker compose"
chown $username /home/$username/$node_folder/docker-compose.yml
chgrp $username /home/$username/$node_folder/docker-compose.yml




cat << "DOCKEREOF"

██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗          
██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║██║████╗  ██║██╔════╝          
██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║██║██╔██╗ ██║██║  ███╗         
██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║██║██║╚██╗██║██║   ██║         
███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝         
╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝          
                                                                                  
██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗                                  
██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗                                 
██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝                                 
██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗                                 
██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║                                 
╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝                                 
                                                                                  
 ██████╗ ██████╗ ███╗   ███╗██████╗  ██████╗ ███████╗███████╗    ██╗   ██╗██████╗ 
██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔═══██╗██╔════╝██╔════╝    ██║   ██║██╔══██╗
██║     ██║   ██║██╔████╔██║██████╔╝██║   ██║███████╗█████╗      ██║   ██║██████╔╝
██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║   ██║╚════██║██╔══╝      ██║   ██║██╔═══╝ 
╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ╚██████╔╝███████║███████╗    ╚██████╔╝██║     
 ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝      ╚═════╝ ╚══════╝╚══════╝     ╚═════╝ ╚═╝     
                                                                                 

DOCKEREOF




read -n 1 -r -s -p $'Press enter to launch docker compose up -d”...\n'
cd /home/$username/$node_folder/
docker compose up -d
echo "Please be patient..."
sleep 15
previous_size_bytes=0
previous_time=$(date +%s)






#!/bin/bash

TARGET_SIZE_GB=34.27  # Hardcoded last known size
previous_size_bytes=0
previous_time=$(date +%s)

while (( $(echo "$total_size_gb <= $TARGET_SIZE_GB" | bc -l) )); do
    current_time=$(date +%s)
    file_count=$(find cache -type f | wc -l)
    total_size_bytes=$(du -sb cache | awk '{print $1}')
    total_size_gb=$(echo "scale=2; $total_size_bytes / 1024 / 1024 / 1024" | bc)

    # Calculate progress percentage
    if (( $(echo "$total_size_gb >= $TARGET_SIZE_GB" | bc -l) )); then
        progress=100
    else
        progress=$(echo "scale=0; ($total_size_gb / $TARGET_SIZE_GB) * 100" | bc)
    fi

    # Calculate download speed (MB/s)
    size_difference=$((total_size_bytes - previous_size_bytes))
    time_difference=$((current_time - previous_time))

    if [ "$time_difference" -gt 0 ]; then
        speed_mb=$(echo "scale=2; $size_difference / 1024 / 1024 / $time_difference" | bc)
    else
        speed_mb=0
    fi

    # Display progress and speed
    if [ "$progress" -ge 100 ]; then
        echo "$(date): Files in cache: $file_count, Total size: ${total_size_gb}GB [100%] Please wait... | Speed: ${speed_mb} MB/s"
    else
        echo "$(date): Files in cache: $file_count, Total size: ${total_size_gb}GB [$progress%] | Speed: ${speed_mb} MB/s"
    fi

    # Store current values for next iteration
    previous_size_bytes=$total_size_bytes
    previous_time=$current_time

    sleep 15
done

echo "✅ Target size reached. Exiting loop!"














# Get health from check from afar
healthResponse=$(curl -s --interface "$(curl -s ifconfig.me)" "$healthurl")

if [[ $healthResponse == "Ok" ]]; then
   echo "${GREEN}Node is OK! You're done! Now why not download uptimerobot app and let it watch KEYWORD Ok at $healthurl so you can be notified when it is offline or failing. ${COLOR_RESET}"
   isOK="true"
   break
else
   echo "${YELLOW}Checking $IP....Node is currently showing:$healthResponse${COLOR_RESET}"
   isOK="false"
fi


echo "End of script.  Done"
