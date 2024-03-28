#!/bin/bash

line_exists() {
    grep -Fxq "$1" "$2"
}

# Function to update the network configuration
update_network_config() {
    # Check if configuration already exists
    if ! grep -q "192.168.16.21" /etc/netplan/*.yaml; then
        # Modify the existing configuration file to update the IP address
        sed -i 's/192.168.16.2/192.168.16.21/' /etc/netplan/*.yaml
        # Apply the new configuration
        netplan apply
        echo "Network configuration updated."
    else
        echo "Network configuration already up to date."
    fi
}

update_hosts_file() {
    # Check if entry already exists
    if line_exists "192.168.16.21 server1" /etc/hosts; then
        echo "Hosts file already up to date."
    else
        # Update hosts file
        sed -i '/server1/d' /etc/hosts # Remove old entry
        echo "192.168.16.21 server1" >> /etc/hosts # Add new entry
        echo "Hosts file updated."
    fi
}

install_software() {
    # Install apache2 and squid
    apt-get update
    apt-get install -y apache2 squid
    # Enable and start services
    systemctl enable apache2 squid
    systemctl start apache2 squid
    echo "Software installed and services started."
}

configure_firewall() {
    # Allow SSH on mgmt network
    ufw allow in on eth2 to any port 22
    # Allow HTTP on both interfaces
    ufw allow in on eth0 to any port 80
    ufw allow in on eth1 to any port 80
    # Allow web proxy on both interfaces
    ufw allow in on eth0 to any port 3128
    ufw allow in on eth1 to any port 3128
    # Enable firewall
    ufw --force enable
    echo "Firewall configured."
}

create_user_accounts() {
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "User '$user' created."
            # Add SSH keys
            mkdir -p "/home/$user/.ssh"
            cp ~/.ssh/id_rsa.pub "/home/$user/.ssh/authorized_keys"
            cp ~/.ssh/id_ed25519.pub "/home/$user/.ssh/authorized_keys"
            chown -R "$user:$user" "/home/$user/.ssh"
            chmod 700 "/home/$user/.ssh"
            chmod 600 "/home/$user/.ssh/authorized_keys"
            echo "SSH keys added for user '$user'."
        else
            echo "User '$user' already exists."
        fi
    done
}

echo "Starting configuration update..."

update_network_config
update_hosts_file
install_software
configure_firewall
create_user_accounts

echo "Configuration update complete."
