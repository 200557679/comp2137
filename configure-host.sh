#!/bin/bash

#This script is written by 200557679 (MOHIT VERMA) for submission of LAB3
# script must ignore TERM, HUP and INT signals.

#Let's create a Function to log changes to syslog
# Specify log file
log_file="scriptlogs.txt"

log_changes() {
    logger -t "configure-host.sh" "$1"
}

log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$log_file"
}

# to print verbose messages
verbose_message() {
    if [ "$verbose" = true ]; then
        echo "$1"
    fi
}


# This script will configure some basic host settings
# updating  hostname
update_hostname() {
    if [ "$(hostname)" != "$desiredName" ]; then
        hostnamectl set-hostname "$desiredName"
        log_changes "Changed hostname to $desiredName"
        verbose_message "Hostname changed to $desiredName"
    fi
}

# This part will  update IP address
update_ip() {
    if [ "$(ip -o -4 addr show "$laninterface" | awk '{print $4}')" != "$desiredIPAddress/24" ]; then
        sed -i "/$laninterface/d" /etc/netplan/*.yaml
        echo "    addresses: [$desiredIPAddress/24]" >> /etc/netplan/*.yaml
        netplan apply
        log_changes "Changed IP address of $laninterface to $desiredIPAddress"
        verbose_message "IP address of $laninterface changed to $desiredIPAddress"
    fi
}

# NOw we are going to update /etc/hosts entry
update_hosts() {
    if ! grep -q "$desiredName" /etc/hosts || ! grep -q "$desiredIPAddress" /etc/hosts; then
        sed -i "/$desiredName/d" /etc/hosts
        echo "$desiredIPAddress $desiredName" >> /etc/hosts
        log_changes "Updated /etc/hosts entry for $desiredName to $desiredIPAddress"
        verbose_message "Updated /etc/hosts entry for $desiredName to $desiredIPAddress"
    fi
}

# Initialize variables
verbose=false
desiredName="Student"
desiredIPAddress=""
laninterface="eth0"  # Change to your LAN interface if different

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -verbose)
            verbose=true
            shift
            ;;
        -name)
            shift
            desiredName="$1"
            shift
            ;;
        -ip)
            shift
            desiredIPAddress="$1"
            shift
            ;;
        -hostentry)
            shift
            desiredName="$1"
            desiredIPAddress="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Ignore signals
trap '' SIGINT SIGTERM SIGHUP

# Check if settings are provided
if [ -z "$desiredName" ] && [ -z "$desiredIPAddress" ]; then
    echo "Error: No settings provided. Please specify at least one setting."
    exit 1
fi

# Update hostname if provided
if [ -n "$desiredName" ]; then
    update_hostname
fi

# Update IP address if provided
if [ -n "$desiredIPAddress" ]; then
    update_ip
fi

# Update /etc/hosts entry if provided
if [ -n "$desiredName" ] && [ -n "$desiredIPAddress" ]; then
    update_hosts
fi

exit 0
