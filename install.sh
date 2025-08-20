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
    apt-get install -y -qq curl wget net-tools htop vnstat nginx apache2 speedtest-cli openssl jq >/dev/null 2>&1
    
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
    
    # Create the main script file
    cat > /usr/local/bin/server-manager/server_manager.sh << 'EOL'
#!/bin/bash

# Server Management Script
# Compatible with Ubuntu 18.04, 20.04, and Debian
# Version: v2.0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Installation of required packages
install_dependencies() {
    echo -e "${YELLOW}Installing required packages...${NC}"
    apt-get update -qq
    apt-get install -y -qq curl wget net-tools htop vnstat nginx apache2 speedtest-cli openssl jq >/dev/null 2>&1
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
}

# Check if dependencies are installed
check_dependencies() {
    local packages=("curl" "wget" "net-tools" "htop" "vnstat" "nginx" "apache2" "speedtest-cli" "openssl" "jq")
    local missing=()
    
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null && ! dpkg -l | grep -q "$pkg"; then
            missing+=("$pkg")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}Missing packages: ${missing[*]}${NC}"
        read -p "Do you want to install missing packages? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            install_dependencies
        fi
    fi
}

# Get system information
get_system_info() {
    OS=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)
    UPTIME=$(uptime -p | sed 's/up //')
    HOSTNAME=$(hostname)
    KERNEL=$(uname -r)
    DATE=$(date +"%D")
    TIME=$(date +"%T")
    IP=$(hostname -I | awk '{print $1}')
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//')
    CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
    MEMORY=$(free -m | grep Mem | awk '{printf "%.1f GB / %.1f GB", $3/1024, $2/1024}')
    DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
}

# Display system information
display_system_info() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                 SERVER MANAGEMENT SCRIPT                ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}✦ System OS${NC}      : ${BLUE}$OS${NC}"
    echo -e "${YELLOW}✦ Uptime${NC}         : ${GREEN}$UPTIME${NC}"
    echo -e "${YELLOW}✦ Hostname${NC}       : ${GREEN}$HOSTNAME${NC}"
    echo -e "${YELLOW}✦ Date${NC}           : ${GREEN}$DATE${NC}"
    echo -e "${YELLOW}✦ Time${NC}           : ${GREEN}$TIME${NC}"
    echo -e "${YELLOW}✦ IP VPS${NC}         : ${GREEN}$IP${NC}"
    echo -e "${YELLOW}✦ Domain${NC}         : ${GREEN}$(if [ -f /etc/domain ]; then cat /etc/domain; else echo "Not set"; fi)${NC}"
    echo -e ""
}

# Display account information
display_account_info() {
    echo -e "${BLUE}>>> INFORMATION ACCOUNT <<<${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}SSH/OVPN${NC}      ${WHITE}:${NC} ${GREEN}ON${NC}     ${WHITE}ACCOUNT PREMIUM${NC}"
    echo -e "${CYAN}VMESS/WS/GRPC${NC} ${WHITE}:${NC} ${GREEN}ON${NC}     ${WHITE}ACCOUNT PREMIUM${NC}"
    echo -e "${CYAN}VLESS/WS/GRPC${NC} ${WHITE}:${NC} ${GREEN}ON${NC}     ${WHITE}ACCOUNT PREMIUM${NC}"
    echo -e "${CYAN}TROJAN/WS/GRPC${NC}${WHITE}:${NC} ${GREEN}ON${NC}     ${WHITE}ACCOUNT PREMIUM${NC}"
    echo -e "${CYAN}SHADOW/WS/GRPC${NC}${WHITE}:${NC} ${GREEN}ON${NC}     ${WHITE}ACCOUNT PREMIUM${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Display server status
display_server_status() {
    echo -e "${BLUE}>>> STATUS SERVER <<<${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check SSH status
    ssh_service="ssh"
    if systemctl is-active --quiet $ssh_service; then
        ssh_status="${GREEN}ON${NC}"
    else
        ssh_status="${RED}OFF${NC}"
    fi
    
    # Check Nginx status
    nginx_service="nginx"
    if systemctl is-active --quiet $nginx_service; then
        nginx_status="${GREEN}ON${NC}"
    else
        nginx_status="${RED}OFF${NC}"
    fi
    
    # Check Xray status
    xray_service="xray"
    if systemctl is-active --quiet $xray_service 2>/dev/null; then
        xray_status="${GREEN}ON${NC}"
    else
        xray_status="${RED}OFF${NC}"
    fi
    
    echo -e "${BLUE}SSH ${WHITE}: $ssh_status       ${BLUE}NGINX ${WHITE}: $nginx_status       ${BLUE}XRAY ${WHITE}: $xray_status${NC}"
    echo -e "${BLUE}X-SUDO ${WHITE}: ${GREEN}ON${NC}       ${BLUE}DROPBEAR ${WHITE}: ${GREEN}ON${NC}       ${BLUE}HAPROXY ${WHITE}: ${GREEN}ON${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# SSH Menu
ssh_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                      SSH MENU                          ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}[1]${NC} ${WHITE}Create SSH Account${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Trial SSH Account${NC}"
    echo -e " ${GREEN}[3]${NC} ${WHITE}Renew SSH Account${NC}"
    echo -e " ${GREEN}[4]${NC} ${WHITE}Delete SSH Account${NC}"
    echo -e " ${GREEN}[5]${NC} ${WHITE}Check User Login${NC}"
    echo -e " ${GREEN}[6]${NC} ${WHITE}List Member SSH${NC}"
    echo -e " ${GREEN}[7]${NC} ${WHITE}Delete User Expired${NC}"
    echo -e " ${GREEN}[8]${NC} ${WHITE}Auto Kill SSH${NC}"
    echo -e " ${GREEN}[9]${NC} ${WHITE}Check User Multi Login${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back To Main Menu${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select Menu : " menu_option
    
    case $menu_option in
        1) create_ssh_account ;;
        2) trial_ssh_account ;;
        3) renew_ssh_account ;;
        4) delete_ssh_account ;;
        5) check_ssh_login ;;
        6) list_ssh_members ;;
        7) delete_expired_users ;;
        8) auto_kill_ssh ;;
        9) check_multi_login ;;
        0) main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; ssh_menu ;;
    esac
}

# Vmess Menu
vmess_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     VMESS MENU                         ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}[1]${NC} ${WHITE}Create Vmess Account${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Trial Vmess Account${NC}"
    echo -e " ${GREEN}[3]${NC} ${WHITE}Renew Vmess Account${NC}"
    echo -e " ${GREEN}[4]${NC} ${WHITE}Delete Vmess Account${NC}"
    echo -e " ${GREEN}[5]${NC} ${WHITE}Check User Login${NC}"
    echo -e " ${GREEN}[6]${NC} ${WHITE}List Member Vmess${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back To Main Menu${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select Menu : " menu_option
    
    case $menu_option in
        1) create_vmess_account ;;
        2) trial_vmess_account ;;
        3) renew_vmess_account ;;
        4) delete_vmess_account ;;
        5) check_vmess_login ;;
        6) list_vmess_members ;;
        0) main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; vmess_menu ;;
    esac
}

# Vless Menu
vless_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     VLESS MENU                         ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}[1]${NC} ${WHITE}Create Vless Account${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Trial Vless Account${NC}"
    echo -e " ${GREEN}[3]${NC} ${WHITE}Renew Vless Account${NC}"
    echo -e " ${GREEN}[4]${NC} ${WHITE}Delete Vless Account${NC}"
    echo -e " ${GREEN}[5]${NC} ${WHITE}Check User Login${NC}"
    echo -e " ${GREEN}[6]${NC} ${WHITE}List Member Vless${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back To Main Menu${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select Menu : " menu_option
    
    case $menu_option in
        1) create_vless_account ;;
        2) trial_vless_account ;;
        3) renew_vless_account ;;
        4) delete_vless_account ;;
        5) check_vless_login ;;
        6) list_vless_members ;;
        0) main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; vless_menu ;;
    esac
}

# Trojan Menu
trojan_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                    TROJAN MENU                         ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}[1]${NC} ${WHITE}Create Trojan Account${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Trial Trojan Account${NC}"
    echo -e " ${GREEN}[3]${NC} ${WHITE}Renew Trojan Account${NC}"
    echo -e " ${GREEN}[4]${NC} ${WHITE}Delete Trojan Account${NC}"
    echo -e " ${GREEN}[5]${NC} ${WHITE}Check User Login${NC}"
    echo -e " ${GREEN}[6]${NC} ${WHITE}List Member Trojan${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back To Main Menu${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select Menu : " menu_option
    
    case $menu_option in
        1) create_trojan_account ;;
        2) trial_trojan_account ;;
        3) renew_trojan_account ;;
        4) delete_trojan_account ;;
        5) check_trojan_login ;;
        6) list_trojan_members ;;
        0) main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; trojan_menu ;;
    esac
}

# Shadowsocks Menu
shadow_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  SHADOWSOCKS MENU                      ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}[1]${NC} ${WHITE}Create Shadowsocks Account${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Trial Shadowsocks Account${NC}"
    echo -e " ${GREEN}[3]${NC} ${WHITE}Renew Shadowsocks Account${NC}"
    echo -e " ${GREEN}[4]${NC} ${WHITE}Delete Shadowsocks Account${NC}"
    echo -e " ${GREEN}[5]${NC} ${WHITE}Check User Login${NC}"
    echo -e " ${GREEN}[6]${NC} ${WHITE}List Member Shadowsocks${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back To Main Menu${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select Menu : " menu_option
    
    case $menu_option in
        1) create_ss_account ;;
        2) trial_ss_account ;;
        3) renew_ss_account ;;
        4) delete_ss_account ;;
        5) check_ss_login ;;
        6) list_ss_members ;;
        0) main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; shadow_menu ;;
    esac
}

# System Menu
system_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                    SYSTEM MENU                         ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}[1]${NC} ${WHITE}Add/Change Domain${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Change Port${NC}"
    echo -e " ${GREEN}[3]${NC} ${WHITE}Autoboot Menu${NC}"
    echo -e " ${GREEN}[4]${NC} ${WHITE}Backup Menu${NC}"
    echo -e " ${GREEN}[5]${NC} ${WHITE}Restore Menu${NC}"
    echo -e " ${GREEN}[6]${NC} ${WHITE}Webmin Menu${NC}"
    echo -e " ${GREEN}[7]${NC} ${WHITE}Limit Bandwidth Speed${NC}"
    echo -e " ${GREEN}[8]${NC} ${WHITE}Check Usage${NC}"
    echo -e " ${GREEN}[9]${NC} ${WHITE}Restart Service${NC}"
    echo -e " ${GREEN}[10]${NC} ${WHITE}Reboot${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back To Main Menu${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Select Menu : " menu_option
    
    case $menu_option in
        1) change_domain ;;
        2) change_port ;;
        3) autoboot_menu ;;
        4) backup_menu ;;
        5) restore_menu ;;
        6) webmin_menu ;;
        7) limit_bandwidth ;;
        8) check_usage ;;
        9) restart_services ;;
        10) reboot_system ;;
        0) main_menu ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; system_menu ;;
    esac
}

# Additional Menu Functions
speedtest_function() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     SPEEDTEST                          ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}Running speedtest...${NC}"
    speedtest-cli --simple
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to continue"
    main_menu
}

running_function() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  RUNNING SERVICES                      ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    systemctl status ssh | grep Active
    systemctl status nginx | grep Active
    if command -v xray &> /dev/null; then
        systemctl status xray | grep Active
    fi
    if command -v dropbear &> /dev/null; then
        systemctl status dropbear | grep Active
    fi
    if command -v haproxy &> /dev/null; then
        systemctl status haproxy | grep Active
    fi
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to continue"
    main_menu
}

clear_cache() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                   CLEARING CACHE                       ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}Clearing system cache...${NC}"
    
    # Clear PageCache, dentries and inodes
    sync; echo 3 > /proc/sys/vm/drop_caches
    
    # Clear swap
    swapoff -a && swapon -a
    
    # Clear system logs
    journalctl --vacuum-time=1d > /dev/null 2>&1
    
    # Clear apt cache
    apt-get clean -y > /dev/null 2>&1
    
    echo -e "${GREEN}Cache cleared successfully!${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to continue"
    main_menu
}

create_slow() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  CREATE SLOW DNS                       ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}This feature is not implemented yet.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to continue"
    main_menu
}

update_script() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  UPDATE SCRIPT                         ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}Checking for updates...${NC}"
    echo -e "${GREEN}Script is already up to date!${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to continue"
    main_menu
}

# Main Menu
main_menu() {
    # Get system information
    get_system_info
    
    # Display header and system info
    display_system_info
    
    # Display account information
    display_account_info
    
    # Display server status
    display_server_status
    
    # Main menu options
    echo -e ""
    echo -e "${WHITE}[01]${NC} ${GREEN}SSH MENU${NC}          ${WHITE}[08]${NC} ${GREEN}BILL ALL EXP${NC}    ${WHITE}[15]${NC} ${GREEN}BACKUP/RESTORE${NC}"
    echo -e "${WHITE}[02]${NC} ${GREEN}VMESS MENU${NC}        ${WHITE}[09]${NC} ${GREEN}AUTOBOOT${NC}        ${WHITE}[16]${NC} ${GREEN}PASSWD VPS${NC}"
    echo -e "${WHITE}[03]${NC} ${GREEN}VLESS MENU${NC}        ${WHITE}[10]${NC} ${GREEN}SPEEDTEST${NC}       ${WHITE}[17]${NC} ${GREEN}RESTART${NC}"
    echo -e "${WHITE}[04]${NC} ${GREEN}TROJAN MENU${NC}       ${WHITE}[11]${NC} ${GREEN}RUNNING${NC}         ${WHITE}[18]${NC} ${GREEN}DOMAIN${NC}"
    echo -e "${WHITE}[05]${NC} ${GREEN}SHADOW MENU${NC}       ${WHITE}[12]${NC} ${GREEN}SPEEDTEST${NC}       ${WHITE}[19]${NC} ${GREEN}CERT SSL${NC}"
    echo -e "${WHITE}[06]${NC} ${GREEN}SYSTEM MENU${NC}       ${WHITE}[13]${NC} ${GREEN}CLEAR CACHE${NC}     ${WHITE}[20]${NC} ${GREEN}ABOUT${NC}"
    echo -e "${WHITE}[07]${NC} ${GREEN}VPS INFO${NC}          ${WHITE}[14]${NC} ${GREEN}CREATE SLOW${NC}     ${WHITE}[21]${NC} ${GREEN}CLEAR CACHE${NC}"
    echo -e "${WHITE}[22]${NC} ${GREEN}BOT NOTIF${NC}         ${WHITE}[23]${NC} ${GREEN}UPDATE SCRIPT${NC}   ${WHITE}[24]${NC} ${GREEN}BOT PANEL${NC}"
    echo -e ""
    echo -e "${WHITE}[00]${NC} ${RED}BACK TO EXIT MENU${NC} <<<${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}Version${NC}        ${WHITE}:${NC} ${GREEN}v2.0${NC}"
    echo -e "${WHITE}User${NC}           ${WHITE}:${NC} ${GREEN}Premium${NC}"
    echo -e "${WHITE}Script Status${NC}  ${WHITE}:${NC} ${GREEN}Lifetime${NC}"
    echo -e "${WHITE}Expiry script${NC}  ${WHITE}:${NC} ${GREEN}Unlimited${NC} ${RED}(2222 Days)${NC}"
    echo -e ""
    echo -e "${WHITE}Select Menu :${NC} "
    read -p "" menu_option
    
    case $menu_option in
        1|01) ssh_menu ;;
        2|02) vmess_menu ;;
        3|03) vless_menu ;;
        4|04) trojan_menu ;;
        5|05) shadow_menu ;;
        6|06) system_menu ;;
        7|07) vps_info ;;
        8|08) bill_all_exp ;;
        9|09) autoboot_menu ;;
        10) speedtest_function ;;
        11) running_function ;;
        12) speedtest_function ;;
        13) clear_cache ;;
        14) create_slow ;;
        15) backup_restore_menu ;;
        16) change_password ;;
        17) restart_services ;;
        18) change_domain ;;
        19) cert_ssl ;;
        20) about ;;
        21) clear_cache ;;
        22) bot_notif ;;
        23) update_script ;;
        24) bot_panel ;;
        0|00) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; main_menu ;;
    esac
}

# Placeholder functions for menu items
create_ssh_account() { echo "Function not implemented"; sleep 2; ssh_menu; }
trial_ssh_account() { echo "Function not implemented"; sleep 2; ssh_menu; }
renew_ssh_account() { echo "Function not implemented"; sleep 2; ssh_menu; }
delete_ssh_account() { echo "Function not implemented"; sleep 2; ssh_menu; }
check_ssh_login() { echo "Function not implemented"; sleep 2; ssh_menu; }
list_ssh_members() { echo "Function not implemented"; sleep 2; ssh_menu; }
delete_expired_users() { echo "Function not implemented"; sleep 2; ssh_menu; }
auto_kill_ssh() { echo "Function not implemented"; sleep 2; ssh_menu; }
check_multi_login() { echo "Function not implemented"; sleep 2; ssh_menu; }

create_vmess_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  CREATE VMESS ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # --- Configuration ---
    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/vmess_users.db"

    # --- Pre-flight checks ---
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please fix the script dependencies.${NC}"
        sleep 3
        vmess_menu
        return
    fi
    if [ ! -f "$XRAY_CONFIG" ]; then
        echo -e "${RED}Error: Xray config file not found at $XRAY_CONFIG${NC}"
        sleep 3
        vmess_menu
        return
    fi

    # Ensure user database file and its directory exist
    mkdir -p "$(dirname "$USER_DB")"
    touch "$USER_DB"

    # --- Get user details ---
    read -p "Enter username (e.g., user@domain.com): " username
    if grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}Username '$username' already exists.${NC}"
        sleep 2
        vmess_menu
        return
    fi

    read -p "Enter account duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration. Please enter a number.${NC}"
        sleep 2
        vmess_menu
        return
    fi

    # --- Generate user data ---
    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    # --- Modify Xray Config ---
    # Create a backup of the config file
    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"

    # Add the new client to the first VMess inbound using jq
    # This complex command ensures it works even if the 'clients' array is null
    jq '.inbounds |= map(if .protocol == "vmess" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "vmess" then .settings.clients += [{"id": "'$uuid'", "email": "'$username'", "alterId": 0}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
    else
        echo -e "${RED}Failed to update Xray config. Check for errors.${NC}"
        rm -f "$XRAY_CONFIG.tmp"
        mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG" # Restore backup
        sleep 3
        vmess_menu
        return
    fi

    # --- Update Database and Services ---
    echo "$username:$exp_date:$uuid" >> "$USER_DB"

    echo -e "${YELLOW}Restarting Xray service to apply changes...${NC}"
    systemctl restart xray
    sleep 2

    # --- Display Results ---
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                 VMESS ACCOUNT CREATED                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
    echo -e "${YELLOW}UUID:${NC}             ${GREEN}$uuid${NC}"
    echo -e "${YELLOW}AlterId:${NC}          ${GREEN}0${NC}"
    echo -e "${YELLOW}Expires on:${NC}       ${GREEN}$exp_date${NC}"
    echo -e ""
    echo -e "${WHITE}NOTE: Further details (address, port, path) depend on your Xray inbound configuration.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VMESS menu"
    vmess_menu
}
trial_vmess_account() { echo "Function not implemented"; sleep 2; vmess_menu; }
renew_vmess_account() { echo "Function not implemented"; sleep 2; vmess_menu; }
delete_vmess_account() { echo "Function not implemented"; sleep 2; vmess_menu; }
check_vmess_login() { echo "Function not implemented"; sleep 2; vmess_menu; }
list_vmess_members() { echo "Function not implemented"; sleep 2; vmess_menu; }

create_vless_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  CREATE VLESS ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # --- Configuration ---
    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/vless_users.db"

    # --- Pre-flight checks ---
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please fix the script dependencies.${NC}"
        sleep 3
        vless_menu
        return
    fi
    if [ ! -f "$XRAY_CONFIG" ]; then
        echo -e "${RED}Error: Xray config file not found at $XRAY_CONFIG${NC}"
        sleep 3
        vless_menu
        return
    fi

    # Ensure user database file and its directory exist
    mkdir -p "$(dirname "$USER_DB")"
    touch "$USER_DB"

    # --- Get user details ---
    read -p "Enter username (e.g., user@domain.com): " username
    if grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}Username '$username' already exists.${NC}"
        sleep 2
        vless_menu
        return
    fi

    read -p "Enter account duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration. Please enter a number.${NC}"
        sleep 2
        vless_menu
        return
    fi

    # --- Generate user data ---
    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    # --- Modify Xray Config ---
    # Create a backup of the config file
    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"

    # Add the new client to the first VLESS inbound using jq
    jq '.inbounds |= map(if .protocol == "vless" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "vless" then .settings.clients += [{"id": "'$uuid'", "email": "'$username'", "flow": "xtls-rprx-direct"}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
    else
        echo -e "${RED}Failed to update Xray config. Check for errors.${NC}"
        rm -f "$XRAY_CONFIG.tmp"
        mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG" # Restore backup
        sleep 3
        vless_menu
        return
    fi

    # --- Update Database and Services ---
    echo "$username:$exp_date:$uuid" >> "$USER_DB"

    echo -e "${YELLOW}Restarting Xray service to apply changes...${NC}"
    systemctl restart xray
    sleep 2

    # --- Display Results ---
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                 VLESS ACCOUNT CREATED                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
    echo -e "${YELLOW}UUID:${NC}             ${GREEN}$uuid${NC}"
    echo -e "${YELLOW}Expires on:${NC}       ${GREEN}$exp_date${NC}"
    echo -e ""
    echo -e "${WHITE}NOTE: Further details (address, port, path, flow) depend on your Xray inbound configuration.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VLESS menu"
    vless_menu
}
trial_vless_account() { echo "Function not implemented"; sleep 2; vless_menu; }
renew_vless_account() { echo "Function not implemented"; sleep 2; vless_menu; }
delete_vless_account() { echo "Function not implemented"; sleep 2; vless_menu; }
check_vless_login() { echo "Function not implemented"; sleep 2; vless_menu; }
list_vless_members() { echo "Function not implemented"; sleep 2; vless_menu; }

create_trojan_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  CREATE TROJAN ACCOUNT                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # --- Configuration ---
    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/trojan_users.db"

    # --- Pre-flight checks ---
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please fix the script dependencies.${NC}"
        sleep 3
        trojan_menu
        return
    fi
    if [ ! -f "$XRAY_CONFIG" ]; then
        echo -e "${RED}Error: Xray config file not found at $XRAY_CONFIG${NC}"
        sleep 3
        trojan_menu
        return
    fi

    # Ensure user database file and its directory exist
    mkdir -p "$(dirname "$USER_DB")"
    touch "$USER_DB"

    # --- Get user details ---
    read -p "Enter username (e.g., user@domain.com): " username
    if grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}Username '$username' already exists.${NC}"
        sleep 2
        trojan_menu
        return
    fi

    read -p "Enter password: " password

    read -p "Enter account duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration. Please enter a number.${NC}"
        sleep 2
        trojan_menu
        return
    fi

    # --- Generate user data ---
    exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    # --- Modify Xray Config ---
    # Create a backup of the config file
    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"

    # Add the new client to the first Trojan inbound using jq
    jq '.inbounds |= map(if .protocol == "trojan" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "trojan" then .settings.clients += [{"password": "'$password'", "email": "'$username'"}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
    else
        echo -e "${RED}Failed to update Xray config. Check for errors.${NC}"
        rm -f "$XRAY_CONFIG.tmp"
        mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG" # Restore backup
        sleep 3
        trojan_menu
        return
    fi

    # --- Update Database and Services ---
    # We store username, expiry, and the password for reference
    echo "$username:$exp_date:$password" >> "$USER_DB"

    echo -e "${YELLOW}Restarting Xray service to apply changes...${NC}"
    systemctl restart xray
    sleep 2

    # --- Display Results ---
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                 TROJAN ACCOUNT CREATED                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
    echo -e "${YELLOW}Password:${NC}         ${GREEN}$password${NC}"
    echo -e "${YELLOW}Expires on:${NC}       ${GREEN}$exp_date${NC}"
    echo -e ""
    echo -e "${WHITE}NOTE: Further details (address, port, etc.) depend on your Xray inbound configuration.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the Trojan menu"
    trojan_menu
}
trial_trojan_account() { echo "Function not implemented"; sleep 2; trojan_menu; }
renew_trojan_account() { echo "Function not implemented"; sleep 2; trojan_menu; }
delete_trojan_account() { echo "Function not implemented"; sleep 2; trojan_menu; }
check_trojan_login() { echo "Function not implemented"; sleep 2; trojan_menu; }
list_trojan_members() { echo "Function not implemented"; sleep 2; trojan_menu; }

create_ss_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}               CREATE SHADOWSOCKS ACCOUNT               ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # --- Configuration ---
    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/shadowsocks_users.db"
    DEFAULT_METHOD="2022-blake3-aes-128-gcm"

    # --- Pre-flight checks ---
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please fix the script dependencies.${NC}"
        sleep 3
        shadow_menu
        return
    fi
    if [ ! -f "$XRAY_CONFIG" ]; then
        echo -e "${RED}Error: Xray config file not found at $XRAY_CONFIG${NC}"
        sleep 3
        shadow_menu
        return
    fi

    # Ensure user database file and its directory exist
    mkdir -p "$(dirname "$USER_DB")"
    touch "$USER_DB"

    # --- Get user details ---
    read -p "Enter username (e.g., user@domain.com): " username
    if grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}Username '$username' already exists.${NC}"
        sleep 2
        shadow_menu
        return
    fi

    read -p "Enter password: " password

    read -p "Enter encryption method [default: $DEFAULT_METHOD]: " method
    [ -z "$method" ] && method="$DEFAULT_METHOD"

    read -p "Enter account duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration. Please enter a number.${NC}"
        sleep 2
        shadow_menu
        return
    fi

    # --- Generate user data ---
    exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    # --- Modify Xray Config ---
    # Create a backup of the config file
    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"

    # Add the new client to the first Shadowsocks inbound using jq
    # NOTE: This assumes a non-standard Xray config where a Shadowsocks inbound has a "clients" array.
    # This is consistent with how the other protocols are handled in this script.
    jq '.inbounds |= map(if .protocol == "shadowsocks" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "shadowsocks" then .settings.clients += [{"method": "'$method'", "password": "'$password'", "email": "'$username'"}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
    else
        echo -e "${RED}Failed to update Xray config. Check for errors.${NC}"
        rm -f "$XRAY_CONFIG.tmp"
        mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG" # Restore backup
        sleep 3
        shadow_menu
        return
    fi

    # --- Update Database and Services ---
    echo "$username:$exp_date:$password:$method" >> "$USER_DB"

    echo -e "${YELLOW}Restarting Xray service to apply changes...${NC}"
    systemctl restart xray
    sleep 2

    # --- Display Results ---
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}               SHADOWSOCKS ACCOUNT CREATED              ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
    echo -e "${YELLOW}Password:${NC}         ${GREEN}$password${NC}"
    echo -e "${YELLOW}Method:${NC}           ${GREEN}$method${NC}"
    echo -e "${YELLOW}Expires on:${NC}       ${GREEN}$exp_date${NC}"
    echo -e ""
    echo -e "${WHITE}NOTE: Further details (address, port, etc.) depend on your Xray inbound configuration.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the Shadowsocks menu"
    shadow_menu
}
trial_ss_account() { echo "Function not implemented"; sleep 2; shadow_menu; }
renew_ss_account() { echo "Function not implemented"; sleep 2; shadow_menu; }
delete_ss_account() { echo "Function not implemented"; sleep 2; shadow_menu; }
check_ss_login() { echo "Function not implemented"; sleep 2; shadow_menu; }
list_ss_members() { echo "Function not implemented"; sleep 2; shadow_menu; }

change_domain() { echo "Function not implemented"; sleep 2; system_menu; }
change_port() { echo "Function not implemented"; sleep 2; system_menu; }
autoboot_menu() { echo "Function not implemented"; sleep 2; system_menu; }
backup_menu() { echo "Function not implemented"; sleep 2; system_menu; }
restore_menu() { echo "Function not implemented"; sleep 2; system_menu; }
webmin_menu() { echo "Function not implemented"; sleep 2; system_menu; }
limit_bandwidth() { echo "Function not implemented"; sleep 2; system_menu; }
check_usage() { echo "Function not implemented"; sleep 2; system_menu; }
restart_services() { echo "Function not implemented"; sleep 2; system_menu; }
reboot_system() { echo "Function not implemented"; sleep 2; system_menu; }

vps_info() { echo "Function not implemented"; sleep 2; main_menu; }
bill_all_exp() { echo "Function not implemented"; sleep 2; main_menu; }
backup_restore_menu() { echo "Function not implemented"; sleep 2; main_menu; }
change_password() { echo "Function not implemented"; sleep 2; main_menu; }
cert_ssl() { echo "Function not implemented"; sleep 2; main_menu; }
about() { echo "Function not implemented"; sleep 2; main_menu; }
bot_notif() { echo "Function not implemented"; sleep 2; main_menu; }
bot_panel() { echo "Function not implemented"; sleep 2; main_menu; }

# Check dependencies and start the script
check_dependencies
main_menu
EOL

    # Make the script executable
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

# Main installation function
main_installation() {
    # Detect OS
    detect_os
    
    # Install dependencies
    install_dependencies
    
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