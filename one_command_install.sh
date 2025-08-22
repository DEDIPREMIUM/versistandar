#!/bin/bash

# One-command installer for Server Management Script
# This script downloads and runs the main installer from the repository.

# --- Configuration ---
# !!! IMPORTANT !!!
# You might need to change this URL to point to your repository's raw files.
BASE_URL="https://raw.githubusercontent.com/username/repo/main"
# !!! IMPORTANT !!!

# --- Color codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Script start ---

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   echo -e "Please run with: ${WHITE}sudo bash $0${NC}"
   exit 1
fi

# Display banner
clear
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}           SERVER MANAGEMENT SCRIPT INSTALLER           ${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "${YELLOW}This script will download and install the Server Management Script.${NC}"
echo -e ""

# Create temporary directory
echo -e "${BLUE}Creating temporary directory...${NC}"
TMP_DIR=$(mktemp -d)
if [ ! -d "$TMP_DIR" ]; then
    echo -e "${RED}Failed to create temporary directory.${NC}"
    exit 1
fi
cd "$TMP_DIR" || exit 1

# Download installer files
echo -e "${BLUE}Downloading installation files from repository...${NC}"
wget -O install.sh "${BASE_URL}/install.sh"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download install.sh. Check the BASE_URL in this script.${NC}"
    cd /
    rm -rf "$TMP_DIR"
    exit 1
fi

wget -O server_manager.sh "${BASE_URL}/server_manager.sh"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download server_manager.sh. Check the BASE_URL in this script.${NC}"
    cd /
    rm -rf "$TMP_DIR"
    exit 1
fi

# Make install script executable
chmod +x install.sh

# Run the installer
# The install.sh script will use the server_manager.sh file from this directory
echo -e "${BLUE}Running the main installer...${NC}"
bash install.sh

# Clean up
echo -e "${BLUE}Cleaning up temporary files...${NC}"
cd /
rm -rf "$TMP_DIR"

echo -e ""
echo -e "${GREEN}Installation process completed.${NC}"
echo -e "${YELLOW}If there were no errors, you can now run the script by typing 'servermgr' in the terminal.${NC}"
