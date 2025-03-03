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

# For output readability
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

shopt -s globstar dotglob


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

# Install traceroute
apt-get install -y traceroute bc
# Update and upgrade all apps
apt-get update -y && apt-get upgrade -y



# Get the current WAN IP
echo "Checking The IP: $serverip"
GetTracertHops() {
    traceroute_output=$(traceroute $serverip)
    hop_count=$(echo "$traceroute_output" | tail -n +2 | wc -l)
    echo "$hop_count"
}

hops=$(GetTracertHops)

echo "########## Checking for CGNAT ##########"

if [ "$hops" -eq 1 ]; then
       echo "${GREEN}You're good. CGNAT not detected${COLOR_RESET}"
else
    echo "${RED}[CGNAT DETECTED ERROR] There were $hops hops detected. Possible CGNAT. Seek advice.${COLOR_RESET}"
    is_cgnat_ip "$serverip"
fi
echo "########################################"

# Function to check if an IP is in the CGNAT range (100.64.0.0/10)
is_cgnat_ip() {
    local ip="$1"

    # Convert IP to integer
    ip_int=$(printf "%u\n" $(echo "$ip" | awk -F'.' '{print ($1 * 256**3) + ($2 * 256**2) + ($3 * 256) + $4}'))

    # CGNAT range: 100.64.0.0 (1681915904) to 100.127.255.255 (1686110207)
    cgnat_start=1681915904  # 100.64.0.0
    cgnat_end=1686110207    # 100.127.255.255

    if [[ "$ip_int" -ge "$cgnat_start" && "$ip_int" -le "$cgnat_end" ]]; then
        echo "Your IP $wan_ip is within a typical CGNAT range (100.64.0.0/10)."
    fi
}

























cat << "MENUEOF"
🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽
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
🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽
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
echo "✅ Your SSH Port No (likely to be 22 if you are not sure)"
echo "✅ Your Ubuntu Username. Leave empty to use current user"
echo "✅ Your Pool Access Key From Your Copi Account Online"
echo "✅ Your WAN side Pool Port No If Changing From 8001"
echo "✅ Your LAN side Port No If Changing From 8001"
echo "✅ Think of a name to call your Docker container or leave it empty for COPINode1"



echo "💡 Note: If you need to copy and paste into terminal, you can paste by Ctrl + Shift + V or by using a right click"

read -n 1 -r -s -p $'Press enter to begin...\n'

read -p "What is your ssh port number (Leave empty or put 22 to use the standard ssh port 22)?: " portno
read -p "What is your ubuntu username (Leave it empty to just use $USER. Any typed username will be created if it does not exist) ?: " username
read -p "What is your pool access key? Please enter or paste it in now from your COPI account:" PoolAccessKey
read -p "What is WAN/Internet side pool pool port no? (Leave it empty to accept 8001 if you do not know):" PoolPortNo
read -p "What is your LAN/Internal network side pool pool port no? (Leave it empty to accept 8001 if you do not know):" LANPortNo
read -p "What do you wish to call your docker container? This is useful when you want to refer to it for commands in future.  (Leave it empty and we will call it COPINode1):" ContainerName

### SET DEFAULTS FOR EMPTY FIELDS
if [[ $portno == "" ]] || [ -z "$portno" ];
then
  portno="22"
fi


if [[ $username == "" ]] || [ -z "$username" ];
then
  username=$USER
fi

if [[ $PoolPortNo == "" ]] || [ -z "$PoolPortNo" ];
then
  PoolPortNo="8001"
fi

if [[ $LANPortNo == "" ]] || [ -z "$LANPortNo" ];
then
  LANPortNo="8001"
fi

if [[ $ContainerName == "" ]] || [ -z "$ContainerName" ];
then
  ContainerName="COPINode1"
fi


if [[ $portno == "" ]] || [[ $username == "" ]] || [[ $PoolAccessKey == "" ]] || [[ $PoolPortNo == "" ]];
then
echo "${RED}Some details were not provided.  Script is now exiting.  Please run again and provide answers to all of the questions${COLOR_RESET}"
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

user_home=$(eval echo "~$username")




serverurl=http://$serverip:$PoolPortNo
healthurl=$serverurl/health


echo "Your health URL will be $healthurl"

apt-get update -y && sudo apt-get upgrade -y

echo "Installing prereqs..."
apt-get update -y && sudo apt-get upgrade -y
#sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Installing Docker if not found
if ! command -v docker &> /dev/null
then
    echo "Docker not found, installing..."
    curl -fsSL https://get.docker.com | bash
else
    echo "Docker is already installed."
fi


#Installing Docker Compose

if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose not found, installing..."
    curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi



docker-compose --version
ubuntuvers=$(lsb_release -rs)
echo "Ubuntu version $ubuntuvers detected"


ufw limit $portno
ufw allow $PoolPortNo/tcp
ufw --force enable

mkdir -p $user_home/$node_folder/

cacheurl="$user_home/$node_folder/cache"


chown -R $username: $user_home/$node_folder/
cd $user_home/$node_folder/


logging_file_name="";

if [[ $action == "filenode" ]];
then

cat <<EOF-SETUP >$user_home/$node_folder/docker-compose.yml
name: cornucopias
services:
    pool-server:
        image: public.ecr.aws/cornucopias/nodes/pool-server:latest
        container_name: $ContainerName
        ports:
          - "$LANPortNo:8001"
        restart: unless-stopped # if you want to manually start the pool server replace “unless-stopped” with “no”
        environment:
            FILENODES_POOL_ACCESS_KEY: $PoolAccessKey
            FILENODES_POOL_PUBLIC_PORT: $PoolPortNo
        volumes:
          - $cacheurl:/cache
EOF-SETUP

fi


echo "Applying chgrp and chown to docker compose"
chown $username $user_home/$node_folder/docker-compose.yml
chgrp $username $user_home/$node_folder/docker-compose.yml




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
cd $user_home/$node_folder/
docker compose up -d
echo "Please be patient ... 🌽🌽🌽"
sleep 15
previous_size_bytes=0
previous_time=$(date +%s)


TARGET_SIZE_GB=34.27  # Hardcoded last known size
previous_size_bytes=0
previous_time=$(date +%s)

# This is quite a poor way of monitoring the progress, we will read the docker logs for the next version.

while true; do
    current_time=$(date +%s)
    file_count=$(find cache -type f | wc -l)
    total_size_bytes=$(du -sb cache | awk '{print $1}')
    total_size_gb=$(echo "scale=2; $total_size_bytes / 1024 / 1024 / 1024" | bc)

    # Calculate progress percentage
    if (( $(echo "$total_size_gb >= $TARGET_SIZE_GB" | bc -l) )); then
        progress=100
    else
    
        progress=$(echo "scale=2; ($total_size_gb / $TARGET_SIZE_GB) * 100" | bc)
        
    fi

    # Check if the total size has reached the target
    if (( $(echo "$total_size_gb >= $TARGET_SIZE_GB" | bc -l) )); then
        echo "✅ Target size reached: $total_size_gb GB."
        break  # Exit the loop if the size is reached
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
    if (( $(echo "$progress >= 100" | bc -l) )); then
        echo "$(date): Files in cache: $file_count, Total size: ${total_size_gb}GB [100%] Please wait... | Speed: ${speed_mb} MB/s"
    else
    
        printf "$(date): Files in cache: $file_count, Total size: ${total_size_gb}GB [%.2f%%] | Speed: %.2f MB/s\n" "$progress" "$speed_mb"
    fi

    # Store current values for next iteration
    previous_size_bytes=$total_size_bytes
    previous_time=$current_time

    sleep 15
done



# Get health from check from afar
healthResponse=$(curl -s --interface "$(curl -s ifconfig.me)" "$healthurl")

if [[ $healthResponse == "Ok" ]]; then
   echo "${GREEN}Node is OK! You're done! Now why not download uptimerobot app and let it watch KEYWORD Ok at $healthurl so you can be notified when it is offline or failing. ${COLOR_RESET}"
   isOK="true"
else
   echo "${YELLOW}Checking $IP....Node is currently showing:$healthResponse${COLOR_RESET}"
   isOK="false"
fi

echo "End of script.  Done"
