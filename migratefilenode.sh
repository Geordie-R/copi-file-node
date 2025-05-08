#!/bin/bash

# This script is for migrating a COPI filenode to a new VPS.

set -eu -o pipefail # fail on error , debug all lines


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

# Update and upgrade all apps - removed for now
# sudo apt-get update -y && sudo apt-get upgrade -y



# Get the current WAN IP
echo "Checking The IP: $serverip"
echo "###############UNFINISHED#########################"



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

███╗   ███╗██╗ ██████╗ ██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
████╗ ████║██║██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
██╔████╔██║██║██║  ███╗██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║
██║╚██╔╝██║██║██║   ██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
██║ ╚═╝ ██║██║╚██████╔╝██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                      
🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽🌽
MENUEOF

echo "Welcome to the COPI File Node Migrator to move to a different VPS . We will begin to ask you a series of questions.  Please have to hand:"
echo "✅ Your Ubuntu Username. Leave empty to use current user"
echo "✅ Your Pool Access Key From Your Copi Account Online if you wish to replace it with a new pool access key"

echo "💡 Note: If you need to copy and paste into terminal, you can paste by Ctrl + Shift + V or by using a right click in most cases."

read -n 1 -r -s -p $'Press enter to begin...\n'

read -p "What is your ubuntu username (Leave it empty to just use $USER) ?: " username
read -p "What is your pool access key if you wish to change it? Please enter or paste it in now from your COPI account.  Leave it blank to not change it:" PoolAccessKey

### SET DEFAULTS FOR EMPTY FIELDS

if [[ $username == "" ]] || [ -z "$username" ];
then
  username=$USER
fi

if id "$username" >/dev/null 2>&1; then
    echo "$username user exists"
else
     echo "${RED}❌ user does not exist...exiting ${COLOR_RESET}"
    exit 1
fi

read -n 1 -r -s -p $'In order for us to work for all kinds of installations, we will now go hunting for your COPI docker-compose.yml file. Please press enter to search..\n'



# This hunts for any docker-compose.yml file containing the word cornucopias. 
# If one exists it auto selects it, if more than one exists it presents the user with a 
# numbered choice list and waits for user input

choose_docker_compose_file() {
    echo "Searching for docker-compose.yml files containing 'cornucopias' under /home/ ..."
    mapfile -t all_matches < <(find /home/ -type f -name "docker-compose.yml" 2>/dev/null)

    matches=()
    for file in "${all_matches[@]}"; do
        if grep -qi "cornucopias" "$file"; then
            matches+=("$file")
        fi
    done

    if [ ${#matches[@]} -eq 0 ]; then
        echo "No docker-compose.yml files containing 'cornucopias' found under /home/"
        return 1
    elif [ ${#matches[@]} -eq 1 ]; then
        selected_path="${matches[0]}"
        echo "Only one matching file found:"
        echo "$selected_path"
        return 0
    fi

    echo "Please find the paths we found for your file. Choose a number to return the path."
    for i in "${!matches[@]}"; do
        printf "%d. %s\n" "$((i+1))" "${matches[$i]}"
    done

    while true; do
        read -rp "Enter your choice [1-${#matches[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#matches[@]} )); then
            selected_path="${matches[$((choice-1))]}"
            return 0
        else
            echo "Invalid choice. Please enter a number between 1 and ${#matches[@]}."
        fi
    done
}




if choose_docker_compose_file; then
    corndockerpath="$selected_path"
    echo "✔️ Cornucopias docker-compose.yml found: $corndockerpath"
else
    echo "❌ No path selected or an error occurred."
    exit 1
fi

 corndockerdir="$(dirname "$corndockerpath")"

echo "Cornucopias directory is $corndockerdir"

get_yaml_value() {
    local key="$1"
    local file="$corndockerpath"

    # Use grep to find the line, then cut to get the value after the colon
    local value=$(grep -E "^[[:space:]]*$key:" "$file" | sed -E "s/^[[:space:]]*$key:[[:space:]]*//")

    echo "$value"
}


PoolPortNo=$(get_yaml_value "FILENODES_POOL_PUBLIC_PORT")


if [[ -n "$PoolPortNo" ]]; then
echo "${GREEN}✔️ Found your pool port number in the docker-compose.yml file: $PoolPortNo ${COLOR_RESET}"
else
echo "${RED}❌ Did not find your pool port number in the docker-compose.yml file: $PoolPortNo ${COLOR_RESET}"
fi



if [[ -n "$PoolAccessKey" ]]; then
    # Replace the line while preserving indentation using '@' as delimiter
    sed -i -E "s@^([[:space:]]*FILENODES_POOL_ACCESS_KEY:).*@\1 $PoolAccessKey@" $corndockerpath
    echo "${GREEN}✔️ Pool Access Key Updated in docker-compose.yml ${COLOR_RESET}"
else
    echo "❌ Did not update pool access key as no key was given or node type is not filenode"
fi



serverurl=http://$serverip:$PoolPortNo
healthurl=$serverurl/health

echo "Your health URL will be $healthurl"

# sudo apt-get update -y && sudo apt-get upgrade -y


docker-compose --version
ubuntuvers=$(lsb_release -rs)
echo "Ubuntu version $ubuntuvers detected"


logging_file_name="";

cd "$corndockerdir/"
destinationIP="217.121.232.111"
destinationPortNo="22"
#UNFINISHED
rsync -avz -e 'ssh -p 22' /home/copi/filenode root@$destinationIP:/home/copi/filenode/
