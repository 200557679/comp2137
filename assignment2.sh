
#!/bin/bash

# Function to check if a line exists in a file
line_exists() {
    grep -Fxq "$1" "$2"
}

# Function to update the network configuration
update_network_config() {
    echo "Updating network configuration..."
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

# Function to update the hosts file
update_hosts_file() {
    echo "Adding server1 to /etc/hosts file if necessary..."
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

# Function to install required software
install_software() {
    echo "Installing required software..."
    # Install apache2 and squid if not already installed
    if ! dpkg -s apache2 squid &> /dev/null; then
        apt-get update
        apt-get install -y apache2 squid
        # Enable and start services
        systemctl enable apache2 squid
        systemctl start apache2 squid
        echo "Software installed and services started."
    else
        echo "Software already installed."
    fi
}

# Function to configure firewall
configure_firewall() {
    echo "Configuring firewall..."
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

# Function to create user accounts
create_user_accounts() {
    echo "Creating user accounts..."
    # List of users
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    # Create users with specified configurations
    for user in "${users[@]}"; do
        # Check if user already exists
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "User '$user' created."
            # Add SSH keys if they exist
            if [ -f "/home/remoteadmin/.ssh/id_rsa.pub" ]; then
                mkdir -p "/home/$user/.ssh"
                cp "/home/remoteadmin/.ssh/id_rsa.pub" "/home/$user/.ssh/authorized_keys" && \
                cp "/home/remoteadmin/.ssh/id_ed25519.pub" "/home/$user/.ssh/authorized_keys" && \
                chown -R "$user:$user" "/home/$user/.ssh" && \
                chmod 700 "/home/$user/.ssh" && \
                chmod 600 "/home/$user/.ssh/authorized_keys" && \
                echo "SSH keys added for user '$user'."
            else
                echo "Failed to copy SSH keys for user '$user'. SSH keys are not available."
            fi
        else
            echo "User '$user' already exists."
        fi
    done
}

# Main script
echo "Starting configuration update..."

update_network_config
update_hosts_file
install_software
configure_firewall
create_user_accounts

echo "Configuration update complete."
