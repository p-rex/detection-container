#!/bin/sh

set -e

# Configure apache settings
hn=`hostname`
sed -E -i -e "s/#ServerName.*/ServerName $hn:80 /g" /etc/httpd/conf/httpd.conf
sed -E -i -e '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
sed -E -i -e 's/DirectoryIndex (.*)$/DirectoryIndex index.php \1/g' /etc/httpd/conf/httpd.conf
chmod u+s /bin/ping
chmod 753 /var/www/html/uploads

# Create a fake mysqldump command to trigger a detection with
cp /bin/cat /bin/mysqldump

# Mark as CS testcontainer
sh -c echo CS_testcontainer starting

#  Start webservices
mkdir -p /run/php-fpm
/usr/sbin/php-fpm
/usr/sbin/httpd -k start

cd /home/eval/


# Define the script execution function based on menu/run
execute_script() {
    local script_number=$1
    local edir='/home/eval/bin/'
    
    # Define the array of script names (copied from menu/run)
    local eitems=(
           "ContainerDrift_Via_File_Creation_and_Execution.sh"
           "Defense_Evasion_via_Rootkit.sh"
           "Execution_via_Command-Line_Interface.sh"
           "Exfiltration_via_Exfiltration_Over_Alternative_Protocol.sh > /dev/null 2>&1"
           "Command_Control_via_Remote_Access.sh"
           "Collection_via_Automated_Collection.sh"
           "Credential_Access_via_Credential_Dumping.sh"
           "Persistence_via_External_Remote_Services.sh"
           "Webserver_Suspicious_Terminal_Spawn.sh"
           "Webserver_Unexpected_Child_of_Web_Service.sh"
           "Webserver_Bash_Reverse_Shell.sh"
           "metasploit/Webserver_Trigger_Metasploit_Payload.sh"
           "Reverse_Shell_Trojan.sh"
           )
    
    # Check if the script number is valid
    if [[ $script_number =~ ^[0-9]+$ ]] && [ $script_number -ge 1 ] && [ $script_number -le ${#eitems[@]} ]; then
        local index=$((script_number - 1))
        local script_name="${eitems[$index]}"
        echo "Executing script: $script_name"
        $edir$script_name
        
        # Log the execution to /tmp/log.txt
        date_str=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$date_str - $script_name" >> /tmp/log.txt
    else
        echo "Invalid script number: $script_number"
    fi
}

echo "Starting file monitoring mode"
echo "Checking /tmp/execute every 5 seconds for script numbers"

# Main loop to check /tmp/execute file every 5 seconds
while true; do
    if [ -f /tmp/execute ]; then
        script_number=$(cat /tmp/execute)
        if [ ! -z "$script_number" ]; then
            echo "Found script number: $script_number"
            execute_script $script_number
            # Delete the file after execution
            rm -f /tmp/execute
        fi
    fi
    sleep 5
done
