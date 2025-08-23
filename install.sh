#!/bin/bash

# Server Management Script Installer
# Compatible with Ubuntu 18.04, 20.04, and Debian
# Version: v1.0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   echo -e "Please run with: ${WHITE}sudo bash install.sh${NC}"
   exit 1
fi

# Display banner
clear
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}           SERVER MANAGEMENT SCRIPT INSTALLER           ${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "${YELLOW}This script will install the Server Management Script on your system.${NC}"
echo -e "${YELLOW}Compatible with Ubuntu 18.04, 20.04, and Debian systems.${NC}"
echo -e ""

# Detect OS
detect_os() {
    source /etc/os-release
    OS="${ID}"
    VERSION="${VERSION_ID}"
    
    echo -e "${BLUE}Detected OS:${NC} ${GREEN}${PRETTY_NAME}${NC}"
    
    # Check if OS is supported
    if [[ "${OS}" == "ubuntu" && ("${VERSION}" == "18.04" || "${VERSION}" == "20.04") ]] || [[ "${OS}" == "debian" ]]; then
        echo -e "${GREEN}OS is supported. Continuing installation...${NC}"
    else
        echo -e "${YELLOW}Warning: Your OS (${PRETTY_NAME}) might not be fully supported.${NC}"
        echo -e "${YELLOW}This script is designed for Ubuntu 18.04, 20.04, and Debian.${NC}"
        echo -e "${YELLOW}Do you want to continue anyway? (y/n)${NC}"
        read -r continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Installation aborted.${NC}"
            exit 1
        fi
    fi
}

# Update system and install dependencies
install_dependencies() {
    echo -e "${BLUE}Updating system packages...${NC}"
    apt-get update -qq
    
    echo -e "${BLUE}Installing required packages...${NC}"
    apt-get install -y -qq curl wget net-tools htop vnstat nginx apache2 speedtest-cli openssl jq dropbear haproxy certbot python3-certbot-nginx >/dev/null 2>&1
    
    # Check if xray is installed, if not, install it
    if ! command -v xray &> /dev/null; then
        echo -e "${BLUE}Installing Xray...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root >/dev/null 2>&1
    fi
    
    echo -e "${GREEN}All dependencies installed successfully.${NC}"
}

# Create installation directory
create_directories() {
    echo -e "${BLUE}Creating installation directories...${NC}"
    
    # Create main directory
    mkdir -p /usr/local/bin/server-manager
    
    # Create data directory
    mkdir -p /usr/local/bin/server-manager/data
    
    echo -e "${GREEN}Directories created successfully.${NC}"
}

# Install server management script
install_script() {
    echo -e "${BLUE}Installing server management script...${NC}"
    
    # The server_manager.sh script should be in the same directory
    if [ ! -f "server_manager.sh" ]; then
        echo -e "${RED}Error: server_manager.sh not found in the current directory.${NC}"
        echo -e "${RED}This script should be run from the temporary directory created by one_command_install.sh${NC}"
        exit 1
    fi
    
    # Copy the script to the installation directory
    cp server_manager.sh /usr/local/bin/server-manager/server_manager.sh
    
    # Make it executable
    chmod +x /usr/local/bin/server-manager/server_manager.sh
    
    echo -e "${GREEN}Server management script installed successfully.${NC}"
}

# Create command shortcut
create_command_shortcut() {
    echo -e "${BLUE}Creating command shortcut...${NC}"
    
    # Create a symbolic link to the script
    ln -sf /usr/local/bin/server-manager/server_manager.sh /usr/local/bin/servermgr
    
    # Make it executable
    chmod +x /usr/local/bin/servermgr
    
    echo -e "${GREEN}Command shortcut created successfully.${NC}"
    echo -e "${GREEN}You can now run the script by typing 'servermgr' in the terminal.${NC}"
}

# Create systemd service
create_service() {
    echo -e "${BLUE}Creating systemd service...${NC}"
    
    # Create systemd service file
    cat > /etc/systemd/system/server-manager.service << EOL
[Unit]
Description=Server Management Script Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/server-manager/server_manager.sh
Restart=on-failure
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=server-manager

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd
    systemctl daemon-reload
    
    echo -e "${GREEN}Systemd service created successfully.${NC}"
}

# Function to get user input
get_user_input() {
    echo -e "${BLUE}--- User Configuration ---${NC}"

    # Get domain
    read -p "Please enter your domain name (e.g., mydomain.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Domain name cannot be empty.${NC}"
        exit 1
    fi
    echo "$DOMAIN" > /etc/domain

    # Get email for SSL
    read -p "Please enter your email address (for Let's Encrypt SSL): " EMAIL
    if [ -z "$EMAIL" ]; then
        echo -e "${RED}Email address cannot be empty.${NC}"
        exit 1
    fi

    # Export for other functions
    export DOMAIN
    export EMAIL

    echo -e "${GREEN}Configuration received. Using domain: $DOMAIN${NC}"
    echo -e ""
}

# Function to set up SSL certificate
setup_ssl() {
    echo -e "${BLUE}--- SSL Certificate Setup ---${NC}"
    echo -e "${YELLOW}Attempting to obtain an SSL certificate for $DOMAIN...${NC}"

    # Run Certbot
    certbot --nginx -d "$DOMAIN" --agree-tos -m "$EMAIL" --non-interactive

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSL certificate obtained and configured successfully!${NC}"
    else
        echo -e "${RED}Failed to obtain SSL certificate.${NC}"
        echo -e "${YELLOW}Please check that your domain points to this server's IP and that port 80 is open.${NC}"
        echo -e "${YELLOW}Continuing installation. You may need to configure SSL manually.${NC}"
    fi
    echo -e ""
}

# Main installation function
main_installation() {
    # Get user input first
    get_user_input

    # Detect OS
    detect_os
    
    # Install dependencies
    install_dependencies
    
    # Set up SSL
    setup_ssl

    # Generate Xray config
    generate_xray_config

    # Create directories
    create_directories
    
    # Install script
    install_script
    
    # Create command shortcut
    create_command_shortcut
    
    # Create service
    create_service
    
    # Display completion message
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Server Management Script has been installed successfully!${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}You can now run the script using the following command:${NC}"
    echo -e "${YELLOW}servermgr${NC}"
    echo -e ""
    echo -e "${WHITE}Would you like to run the script now? (y/n)${NC}"
    read -r run_now
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        /usr/local/bin/servermgr
    else
        echo -e "${GREEN}You can run the script later by typing 'servermgr' in the terminal.${NC}"
    fi
}

# Run the installation
main_installation