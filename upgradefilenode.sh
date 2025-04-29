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

# Update and upgrade all apps
sudo apt-get update -y && sudo apt-get upgrade -y



# Get the current WAN IP
echo "Checking The IP: $serverip"
echo "########################################"



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

██╗   ██╗██████╗  ██████╗ ██████╗  █████╗ ██████╗ ███████╗
██║   ██║██╔══██╗██╔════╝ ██╔══██╗██╔══██╗██╔══██╗██╔════╝
██║   ██║██████╔╝██║  ███╗██████╔╝███████║██║  ██║█████╗  
██║   ██║██╔═══╝ ██║   ██║██╔══██╗██╔══██║██║  ██║██╔══╝  
╚██████╔╝██║     ╚██████╔╝██║  ██║██║  ██║██████╔╝███████╗
 ╚═════╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝ 
🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽
MENUEOF

PS3='Please choose what type of node you are upgrading today.  File node is only available for now. Please write the number of the menu item and press enter: '
filenode="Upgrade a COPI File Node"
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
        echo "You chose a file node upgrade"
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


echo "Welcome to the COPI File Node Upgrade . We will begin to ask you a series of questions.  Please have to hand:"
echo "✅ Your Ubuntu Username. Leave empty to use current user"
echo "✅ Your Pool Access Key From Your Copi Account Online if you wish to replace it with a new pool access key"

echo "💡 Note: If you need to copy and paste into terminal, you can paste by Ctrl + Shift + V or by using a right click"

read -n 1 -r -s -p $'Press enter to begin...\n'

read -p "What is your ubuntu username (Leave it empty to just use $USER. Any typed username will be created if it does not exist) ?: " username
read -p "What is your pool access key if you wish to change it? Please enter or paste it in now from your COPI account.  Leave it blank to not change it:" PoolAccessKey

### SET DEFAULTS FOR EMPTY FIELDS

if [[ $username == "" ]] || [ -z "$username" ];
then
  username=$USER
fi


#########################################
# Create $username user if needed
#########################################

if id "$username" >/dev/null 2>&1; then
    echo "user exists"
else
     echo "${RED}user does not exist...exiting ${COLOR_RESET}"
    exit 1
fi




#Setting paths
user_home=$(eval echo "~$username")
cacheurl="$user_home/$node_folder/cache"
cd $user_home/$node_folder/

get_yaml_value() {
    local key="$1"
    local file="docker-compose.yml"

    # Use grep to find the line, then cut to get the value after the colon
    local value=$(grep -E "^[[:space:]]*$key:" "$file" | sed -E "s/^[[:space:]]*$key:[[:space:]]*//")

    echo "$value"
}


PoolPortNo=$(get_yaml_value "FILENODES_POOL_PUBLIC_PORT")


if [[ -n "$PoolPortNo" ]]; then
echo "${GREEN}Found your pool port number in the docker-compose.yml file: $PoolPortNo ${COLOR_RESET}"
else
echo "${RED}Did not find your pool port number in the docker-compose.yml file: $PoolPortNo ${COLOR_RESET}"
fi



if [[ -n "$PoolAccessKey" && $action == "filenode" ]]; then
     # Replace the line while preserving indentation
    sed -i -E "s/^([[:space:]]*FILENODES_POOL_ACCESS_KEY:).*/\1 $PoolAccessKey/" docker-compose.yml
    echo "${GREEN}Pool Access Key Updated in docker-compose.yml ${COLOR_RESET}"
else
    echo "Did not update pool access key as no key was given or node type is not filenode"
fi


serverurl=http://$serverip:$PoolPortNo
healthurl=$serverurl/health

echo "Your health URL will be $healthurl"

sudo apt-get update -y && sudo apt-get upgrade -y


docker-compose --version
ubuntuvers=$(lsb_release -rs)
echo "Ubuntu version $ubuntuvers detected"





if [[ -f docker-compose.yml ]]; then
    echo "${GREEN}Found the docker-compose.yml file! ${COLOR_RESET}"
else
    echo "${RED}Could not find docker-compose.yml - exiting! ${COLOR_RESET}"
    exit 1
fi
 







logging_file_name="";



read -n 1 -r -s -p $'Press enter to do a docker compose pull -d...\n'


sudo docker compose pull

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
sudo docker compose up -d
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

echo "End of script.  Done."
