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
create_ssh_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                    CREATE SSH ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Get username
    read -p "Enter username: " username
    if id "$username" &>/dev/null; then
        echo -e "${RED}Username '$username' already exists.${NC}"
        sleep 2
        ssh_menu
        return
    fi

    # Get password
    read -p "Enter password: " password

    # Get expiration
    read -p "Enter account duration (days): " duration

    # Calculate expiration date
    exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    # Create user
    useradd -e "$exp_date" -s /bin/false -M "$username" >/dev/null 2>&1
    echo "$username:$password" | chpasswd

    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  SSH ACCOUNT CREATED                   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}Host/IP:${NC}       ${GREEN}$(hostname -I | awk '{print $1}')${NC}"
    echo -e "${YELLOW}Username:${NC}      ${GREEN}$username${NC}"
    echo -e "${YELLOW}Password:${NC}      ${GREEN}$password${NC}"
    echo -e "${YELLOW}Expires on:${NC}    ${GREEN}$exp_date${NC}"
    echo -e ""
    echo -e "${WHITE}You can now use an SSH client like PuTTY or OpenSSH to connect.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
trial_ssh_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     TRIAL SSH ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Get username
    read -p "Enter username for trial account: " username
    if id "$username" &>/dev/null; then
        echo -e "${RED}Username '$username' already exists.${NC}"
        sleep 2
        ssh_menu
        return
    fi

    # Generate a random password
    password=$(openssl rand -base64 12)

    # Set expiration to 24 hours from now
    duration_hours=24
    exp_date=$(date -d "+$duration_hours hours" +"%Y-%m-%d %H:%M:%S")

    # Create user
    # The -e flag for useradd expects YYYY-MM-DD format
    useradd_exp_date=$(date -d "+$duration_hours hours" +"%Y-%m-%d")
    useradd -e "$useradd_exp_date" -s /bin/false -M "$username" >/dev/null 2>&1
    echo "$username:$password" | chpasswd

    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  TRIAL ACCOUNT CREATED                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}Host/IP:${NC}       ${GREEN}$(hostname -I | awk '{print $1}')${NC}"
    echo -e "${YELLOW}Username:${NC}      ${GREEN}$username${NC}"
    echo -e "${YELLOW}Password:${NC}      ${GREEN}$password${NC}"
    echo -e "${YELLOW}Expires on:${NC}    ${GREEN}$exp_date (24 Hours)${NC}"
    echo -e ""
    echo -e "${WHITE}This is a trial account and will expire in 24 hours.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
renew_ssh_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     RENEW SSH ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    read -p "Enter username to renew: " username

    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}Username '$username' does not exist.${NC}"
        sleep 2
        ssh_menu
        return
    fi

    read -p "Enter renewal duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration. Please enter a number.${NC}"
        sleep 2
        ssh_menu
        return
    fi

    # Calculate new expiration date
    new_exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    # Renew user using chage
    chage -E "$new_exp_date" "$username" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e ""
        echo -e "${GREEN}Account '$username' has been successfully renewed.${NC}"
        echo -e "${YELLOW}New expiration date:${NC} ${GREEN}$new_exp_date${NC}"
        echo -e ""
    else
        echo -e "${RED}Failed to renew account '$username'.${NC}"
        sleep 2
        ssh_menu
        return
    fi

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
delete_ssh_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                    DELETE SSH ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    read -p "Enter username to delete: " username

    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}Username '$username' does not exist.${NC}"
        sleep 2
        ssh_menu
        return
    fi

    echo -e "${YELLOW}Are you sure you want to delete the user '$username'?${NC}"
    read -p "This action cannot be undone. (y/n): " choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        # Delete user
        userdel -r "$username" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e ""
            echo -e "${GREEN}Account '$username' has been successfully deleted.${NC}"
            echo -e ""
        else
            echo -e "${RED}Failed to delete account '$username'.${NC}"
            sleep 2
            ssh_menu
            return
        fi
    else
        echo -e "${YELLOW}Deletion cancelled.${NC}"
    fi

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
check_ssh_login() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                    CHECK USER LOGIN                    ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}List of currently logged in users:${NC}"
    echo -e "------------------------------------"
    who
    echo -e "------------------------------------"
    echo -e ""

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
list_ssh_members() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     LIST SSH MEMBERS                     ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    # Get list of non-system users
    # We consider users with UID >= 1000 as managed by this script
    user_list=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd)

    if [ -z "$user_list" ]; then
        echo -e "${YELLOW}No SSH users found.${NC}"
    else
        printf "%-20s | %-15s\n" "USERNAME" "EXPIRES ON"
        echo -e "---------------------------------------"
        while IFS= read -r user; do
            # Get expiration date
            exp_date=$(chage -l "$user" | grep 'Account expires' | cut -d: -f2 | sed 's/^[ \t]*//')
            if [ -z "$exp_date" ] || [ "$exp_date" == "never" ]; then
                exp_date="Never"
            fi
            printf "%-20s | %-15s\n" "$user" "$exp_date"
        done <<< "$user_list"
        echo -e "---------------------------------------"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
delete_expired_users() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  DELETE EXPIRED USERS                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    today_epoch=$(date +%s)
    deleted_count=0

    # Get list of non-system users
    user_list=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd)

    if [ -z "$user_list" ]; then
        echo -e "${YELLOW}No users to check.${NC}"
        sleep 2
        ssh_menu
        return
    fi

    for user in $user_list; do
        # Get expiration date in epoch format
        exp_date_str=$(chage -l "$user" | grep 'Account expires' | cut -d: -f2 | sed 's/^[ \t]*//')

        if [ -n "$exp_date_str" ] && [ "$exp_date_str" != "never" ]; then
            exp_epoch=$(date -d "$exp_date_str" +%s)

            if [ "$exp_epoch" -lt "$today_epoch" ]; then
                echo -e "${YELLOW}User '$user' has expired. Deleting...${NC}"
                userdel -r "$user" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}User '$user' deleted successfully.${NC}"
                    ((deleted_count++))
                else
                    echo -e "${RED}Failed to delete user '$user'.${NC}"
                fi
            fi
        fi
    done

    if [ "$deleted_count" -eq 0 ]; then
        echo -e "${GREEN}No expired users found to delete.${NC}"
    else
        echo -e ""
        echo -e "${GREEN}Finished. Deleted $deleted_count expired user(s).${NC}"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
auto_kill_ssh() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  AUTO KILL SSH SESSIONS                ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    # Get a list of users with more than one session
    users_to_kill=$(who | awk '{print $1}' | sort | uniq -c | awk '$1 > 1 {print $2}')

    if [ -z "$users_to_kill" ]; then
        echo -e "${GREEN}No users with multiple logins found to kill.${NC}"
    else
        echo -e "${YELLOW}The following users have multiple logins and will be kicked:${NC}"
        echo -e "${CYAN}$users_to_kill${NC}"
        echo -e ""
        read -p "Are you sure you want to proceed? (y/n): " choice

        if [[ "$choice" =~ ^[Yy]$ ]]; then
            for user in $users_to_kill; do
                echo -e "${YELLOW}Kicking all sessions for user '$user'...${NC}"
                # The -u flag pkill's processes by user
                pkill -u "$user"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Successfully kicked '$user'.${NC}"
                else
                    # This might happen if the sessions ended between the check and the pkill
                    echo -e "${YELLOW}Could not kick '$user' (sessions might have ended).${NC}"
                fi
            done
            echo -e ""
            echo -e "${GREEN}Auto-kill process completed.${NC}"
        else
            echo -e "${YELLOW}Operation cancelled.${NC}"
        fi
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}
check_multi_login() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}               CHECK USER MULTI-LOGIN                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    # Get a list of users and their session counts, then filter for counts > 1
    multi_login_users=$(who | awk '{print $1}' | sort | uniq -c | awk '$1 > 1 {print "User \047" $2 "\047 is logged in " $1 " times."}')

    if [ -z "$multi_login_users" ]; then
        echo -e "${GREEN}No users with multiple logins found.${NC}"
    else
        echo -e "${YELLOW}Users with multiple logins detected:${NC}"
        echo -e "---------------------------------------"
        echo -e "${CYAN}$multi_login_users${NC}"
        echo -e "---------------------------------------"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the SSH menu"
    ssh_menu
}

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
trial_vmess_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  TRIAL VMESS ACCOUNT                   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    # --- Configuration ---
    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/vmess_users.db"

    # --- Pre-flight checks ---
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed.${NC}"; sleep 2; vmess_menu; return;
    fi
    if [ ! -f "$XRAY_CONFIG" ]; then
        echo -e "${RED}Error: Xray config file not found.${NC}"; sleep 2; vmess_menu; return;
    fi

    # Ensure user database file and its directory exist
    mkdir -p "$(dirname "$USER_DB")"
    touch "$USER_DB"

    # --- Generate user data ---
    username="trial-$(openssl rand -hex 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp_date=$(date -d "+24 hours" +"%Y-%m-%d")

    echo -e "${YELLOW}Creating 24-hour trial account: ${CYAN}$username${NC}"
    sleep 2

    # --- Modify Xray Config ---
    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"
    jq '.inbounds |= map(if .protocol == "vmess" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "vmess" then .settings.clients += [{"id": "'$uuid'", "email": "'$username'", "alterId": 0}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
    else
        echo -e "${RED}Failed to update Xray config.${NC}"; rm -f "$XRAY_CONFIG.tmp"; mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG"; sleep 2; vmess_menu; return;
    fi

    # --- Update Database and Services ---
    echo "$username:$exp_date:$uuid" >> "$USER_DB"
    systemctl restart xray

    # --- Display Results ---
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                 TRIAL VMESS ACCOUNT CREATED              ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
    echo -e "${YELLOW}UUID:${NC}             ${GREEN}$uuid${NC}"
    echo -e "${YELLOW}AlterId:${NC}          ${GREEN}0${NC}"
    echo -e "${YELLOW}Expires in:${NC}       ${GREEN}24 Hours${NC}"
    echo -e ""
    echo -e "${WHITE}NOTE: Further details depend on your Xray inbound configuration.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VMESS menu"
    vmess_menu
}
renew_vmess_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                   RENEW VMESS ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/vmess_users.db"

    read -p "Enter username (email) to renew: " username

    # Check if user exists in our DB
    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"
        sleep 2
        vmess_menu
        return
    fi

    read -p "Enter renewal duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration. Please enter a number.${NC}"
        sleep 2
        vmess_menu
        return
    fi

    # Get the rest of the user data
    user_data=$(grep "^${username}:" "$USER_DB")
    uuid=$(echo "$user_data" | cut -d: -f3)

    # Calculate new expiration date
    new_exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    # Update the user's line in the database
    sed -i "s/^${username}:.*$/${username}:${new_exp_date}:${uuid}/" "$USER_DB"

    if [ $? -eq 0 ]; then
        echo -e ""
        echo -e "${GREEN}Account '$username' has been successfully renewed.${NC}"
        echo -e "${YELLOW}New expiration date:${NC} ${GREEN}$new_exp_date${NC}"
        echo -e ""
    else
        echo -e "${RED}Failed to renew account '$username'.${NC}"
        sleep 2
        vmess_menu
        return
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VMESS menu"
    vmess_menu
}
delete_vmess_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  DELETE VMESS ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/vmess_users.db"

    read -p "Enter username (email) to delete: " username

    # Check if user exists in our DB
    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"
        sleep 2
        vmess_menu
        return
    fi

    # Get user's UUID from DB
    uuid=$(grep "^${username}:" "$USER_DB" | cut -d: -f3)

    echo -e "${YELLOW}Are you sure you want to delete the user '$username'?${NC}"
    read -p "This action cannot be undone. (y/n): " choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        # Create a backup of the config file
        cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"

        # Remove client from Xray config using jq
        # This command deletes the client object that has the matching ID
        jq '.inbounds |= map(if .protocol == "vmess" then .settings.clients |= del(.[] | select(.id == "'$uuid'")) else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

        if [ $? -eq 0 ]; then
            mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"

            # Remove user from our database
            sed -i "/^${username}:/d" "$USER_DB"

            echo -e "${YELLOW}Restarting Xray service...${NC}"
            systemctl restart xray
            sleep 2

            echo -e ""
            echo -e "${GREEN}Account '$username' has been successfully deleted.${NC}"
            echo -e ""
        else
            echo -e "${RED}Failed to update Xray config. Check for errors.${NC}"
            rm -f "$XRAY_CONFIG.tmp"
            mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG" # Restore backup
            sleep 3
            vmess_menu
            return
        fi
    else
        echo -e "${YELLOW}Deletion cancelled.${NC}"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VMESS menu"
    vmess_menu
}
check_vmess_login() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  CHECK VMESS USER INFO                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/vmess_users.db"

    read -p "Enter username (email) to check: " username

    if [ ! -f "$USER_DB" ] || ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"
        sleep 2
        vmess_menu
        return
    fi

    user_data=$(grep "^${username}:" "$USER_DB")
    exp_date=$(echo "$user_data" | cut -d: -f2)
    uuid=$(echo "$user_data" | cut -d: -f3)

    echo -e "${YELLOW}User Details:${NC}"
    echo -e "---------------------------------------"
    echo -e "  ${CYAN}Username:${NC}  $username"
    echo -e "  ${CYAN}UUID:${NC}      $uuid"
    echo -e "  ${CYAN}Expires on:${NC} $exp_date"
    echo -e "---------------------------------------"
    echo -e ""
    echo -e "${WHITE}Note: This check confirms the user exists in the system.${NC}"
    echo -e "${WHITE}It does not show live connection status.${NC}"
    echo -e ""

    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VMESS menu"
    vmess_menu
}
list_vmess_members() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     LIST VMESS MEMBERS                   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/vmess_users.db"

    if [ ! -f "$USER_DB" ] || ! [ -s "$USER_DB" ]; then
        echo -e "${YELLOW}No VMESS users found.${NC}"
    else
        printf "%-25s | %-15s\n" "USERNAME (EMAIL)" "EXPIRES ON"
        echo -e "-------------------------------------------"
        while IFS= read -r line; do
            user=$(echo "$line" | cut -d: -f1)
            exp_date=$(echo "$line" | cut -d: -f2)
            printf "%-25s | %-15s\n" "$user" "$exp_date"
        done < "$USER_DB"
        echo -e "-------------------------------------------"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VMESS menu"
    vmess_menu
}

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
trial_vless_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  TRIAL VLESS ACCOUNT                   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/vless_users.db"

    if ! command -v jq &> /dev/null; then echo -e "${RED}Error: jq is not installed.${NC}"; sleep 2; vless_menu; return; fi
    if [ ! -f "$XRAY_CONFIG" ]; then echo -e "${RED}Error: Xray config file not found.${NC}"; sleep 2; vless_menu; return; fi

    mkdir -p "$(dirname "$USER_DB")"; touch "$USER_DB"
    username="trial-$(openssl rand -hex 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp_date=$(date -d "+24 hours" +"%Y-%m-%d")

    echo -e "${YELLOW}Creating 24-hour trial account: ${CYAN}$username${NC}"; sleep 2

    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"
    jq '.inbounds |= map(if .protocol == "vless" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "vless" then .settings.clients += [{"id": "'$uuid'", "email": "'$username'", "flow": "xtls-rprx-direct"}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
        echo "$username:$exp_date:$uuid" >> "$USER_DB"
        systemctl restart xray

        clear
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}                 TRIAL VLESS ACCOUNT CREATED              ${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e ""
        echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
        echo -e "${YELLOW}UUID:${NC}             ${GREEN}$uuid${NC}"
        echo -e "${YELLOW}Expires in:${NC}       ${GREEN}24 Hours${NC}"
        echo -e ""
    else
        echo -e "${RED}Failed to update Xray config.${NC}"; rm -f "$XRAY_CONFIG.tmp"; mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG"; sleep 2;
    fi

    read -n 1 -s -r -p "Press any key to return to the VLESS menu"
    vless_menu
}
renew_vless_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                   RENEW VLESS ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/vless_users.db"
    read -p "Enter username (email) to renew: " username

    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; vless_menu; return;
    fi

    read -p "Enter renewal duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration.${NC}"; sleep 2; vless_menu; return;
    fi

    user_data=$(grep "^${username}:" "$USER_DB")
    uuid=$(echo "$user_data" | cut -d: -f3)
    new_exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    sed -i "s/^${username}:.*$/${username}:${new_exp_date}:${uuid}/" "$USER_DB"

    echo -e "\n${GREEN}Account '$username' renewed successfully.${NC}"
    echo -e "${YELLOW}New expiration date:${NC} ${GREEN}$new_exp_date${NC}\n"

    read -n 1 -s -r -p "Press any key to return to the VLESS menu"
    vless_menu
}
delete_vless_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  DELETE VLESS ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/vless_users.db"

    read -p "Enter username (email) to delete: " username
    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; vless_menu; return;
    fi

    uuid=$(grep "^${username}:" "$USER_DB" | cut -d: -f3)

    read -p "Are you sure you want to delete '$username'? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"
        jq '.inbounds |= map(if .protocol == "vless" then .settings.clients |= del(.[] | select(.id == "'$uuid'")) else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

        if [ $? -eq 0 ]; then
            mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
            sed -i "/^${username}:/d" "$USER_DB"
            systemctl restart xray
            echo -e "\n${GREEN}Account '$username' deleted successfully.${NC}\n"
        else
            echo -e "${RED}Failed to update Xray config.${NC}"; rm -f "$XRAY_CONFIG.tmp"; mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG"; sleep 2;
        fi
    else
        echo -e "${YELLOW}Deletion cancelled.${NC}"
    fi

    read -n 1 -s -r -p "Press any key to return to the VLESS menu"
    vless_menu
}
check_vless_login() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  CHECK VLESS USER INFO                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/vless_users.db"
    read -p "Enter username (email) to check: " username

    if [ ! -f "$USER_DB" ] || ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; vless_menu; return;
    fi

    user_data=$(grep "^${username}:" "$USER_DB")
    exp_date=$(echo "$user_data" | cut -d: -f2)
    uuid=$(echo "$user_data" | cut -d: -f3)

    echo -e "${YELLOW}User Details:${NC}"
    echo -e "---------------------------------------"
    echo -e "  ${CYAN}Username:${NC}  $username"
    echo -e "  ${CYAN}UUID:${NC}      $uuid"
    echo -e "  ${CYAN}Expires on:${NC} $exp_date"
    echo -e "---------------------------------------"
    echo -e "\n${WHITE}Note: This check confirms the user exists in the system.${NC}"

    read -n 1 -s -r -p "Press any key to return to the VLESS menu"
    vless_menu
}
list_vless_members() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     LIST VLESS MEMBERS                   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/vless_users.db"

    if [ ! -f "$USER_DB" ] || ! [ -s "$USER_DB" ]; then
        echo -e "${YELLOW}No VLESS users found.${NC}"
    else
        printf "%-25s | %-15s\n" "USERNAME (EMAIL)" "EXPIRES ON"
        echo -e "-------------------------------------------"
        while IFS= read -r line; do
            user=$(echo "$line" | cut -d: -f1)
            exp_date=$(echo "$line" | cut -d: -f2)
            printf "%-25s | %-15s\n" "$user" "$exp_date"
        done < "$USER_DB"
        echo -e "-------------------------------------------"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the VLESS menu"
    vless_menu
}

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
trial_trojan_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  TRIAL TROJAN ACCOUNT                  ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/trojan_users.db"

    if ! command -v jq &> /dev/null; then echo -e "${RED}Error: jq is not installed.${NC}"; sleep 2; trojan_menu; return; fi
    if [ ! -f "$XRAY_CONFIG" ]; then echo -e "${RED}Error: Xray config file not found.${NC}"; sleep 2; trojan_menu; return; fi

    mkdir -p "$(dirname "$USER_DB")"; touch "$USER_DB"
    username="trial-$(openssl rand -hex 4)"
    password=$(openssl rand -hex 8)
    exp_date=$(date -d "+24 hours" +"%Y-%m-%d")

    echo -e "${YELLOW}Creating 24-hour trial account: ${CYAN}$username${NC}"; sleep 2

    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"
    jq '.inbounds |= map(if .protocol == "trojan" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "trojan" then .settings.clients += [{"password": "'$password'", "email": "'$username'"}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
        echo "$username:$exp_date:$password" >> "$USER_DB"
        systemctl restart xray

        clear
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}                TRIAL TROJAN ACCOUNT CREATED              ${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e ""
        echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
        echo -e "${YELLOW}Password:${NC}         ${GREEN}$password${NC}"
        echo -e "${YELLOW}Expires in:${NC}       ${GREEN}24 Hours${NC}"
        echo -e ""
    else
        echo -e "${RED}Failed to update Xray config.${NC}"; rm -f "$XRAY_CONFIG.tmp"; mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG"; sleep 2;
    fi

    read -n 1 -s -r -p "Press any key to return to the Trojan menu"
    trojan_menu
}
renew_trojan_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                   RENEW TROJAN ACCOUNT                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/trojan_users.db"
    read -p "Enter username (email) to renew: " username

    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; trojan_menu; return;
    fi

    read -p "Enter renewal duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration.${NC}"; sleep 2; trojan_menu; return;
    fi

    user_data=$(grep "^${username}:" "$USER_DB")
    password=$(echo "$user_data" | cut -d: -f3)
    new_exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    sed -i "s/^${username}:.*$/${username}:${new_exp_date}:${password}/" "$USER_DB"

    echo -e "\n${GREEN}Account '$username' renewed successfully.${NC}"
    echo -e "${YELLOW}New expiration date:${NC} ${GREEN}$new_exp_date${NC}\n"

    read -n 1 -s -r -p "Press any key to return to the Trojan menu"
    trojan_menu
}
delete_trojan_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  DELETE TROJAN ACCOUNT                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/trojan_users.db"

    read -p "Enter username (email) to delete: " username
    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; trojan_menu; return;
    fi

    read -p "Are you sure you want to delete '$username'? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"
        # Delete user by email, which should be unique
        jq '.inbounds |= map(if .protocol == "trojan" then .settings.clients |= del(.[] | select(.email == "'$username'")) else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

        if [ $? -eq 0 ]; then
            mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
            sed -i "/^${username}:/d" "$USER_DB"
            systemctl restart xray
            echo -e "\n${GREEN}Account '$username' deleted successfully.${NC}\n"
        else
            echo -e "${RED}Failed to update Xray config.${NC}"; rm -f "$XRAY_CONFIG.tmp"; mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG"; sleep 2;
        fi
    else
        echo -e "${YELLOW}Deletion cancelled.${NC}"
    fi

    read -n 1 -s -r -p "Press any key to return to the Trojan menu"
    trojan_menu
}
check_trojan_login() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  CHECK TROJAN USER INFO                ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/trojan_users.db"
    read -p "Enter username (email) to check: " username

    if [ ! -f "$USER_DB" ] || ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; trojan_menu; return;
    fi

    user_data=$(grep "^${username}:" "$USER_DB")
    exp_date=$(echo "$user_data" | cut -d: -f2)
    password=$(echo "$user_data" | cut -d: -f3)

    echo -e "${YELLOW}User Details:${NC}"
    echo -e "---------------------------------------"
    echo -e "  ${CYAN}Username:${NC}  $username"
    echo -e "  ${CYAN}Password:${NC}  $password"
    echo -e "  ${CYAN}Expires on:${NC} $exp_date"
    echo -e "---------------------------------------"
    echo -e "\n${WHITE}Note: This check confirms the user exists in the system.${NC}"

    read -n 1 -s -r -p "Press any key to return to the Trojan menu"
    trojan_menu
}
list_trojan_members() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                    LIST TROJAN MEMBERS                   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/trojan_users.db"

    if [ ! -f "$USER_DB" ] || ! [ -s "$USER_DB" ]; then
        echo -e "${YELLOW}No Trojan users found.${NC}"
    else
        printf "%-25s | %-15s\n" "USERNAME (EMAIL)" "EXPIRES ON"
        echo -e "-------------------------------------------"
        while IFS= read -r line; do
            user=$(echo "$line" | cut -d: -f1)
            exp_date=$(echo "$line" | cut -d: -f2)
            printf "%-25s | %-15s\n" "$user" "$exp_date"
        done < "$USER_DB"
        echo -e "-------------------------------------------"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the Trojan menu"
    trojan_menu
}

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
trial_ss_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                TRIAL SHADOWSOCKS ACCOUNT               ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/shadowsocks_users.db"
    DEFAULT_METHOD="2022-blake3-aes-128-gcm"

    if ! command -v jq &> /dev/null; then echo -e "${RED}Error: jq is not installed.${NC}"; sleep 2; shadow_menu; return; fi
    if [ ! -f "$XRAY_CONFIG" ]; then echo -e "${RED}Error: Xray config file not found.${NC}"; sleep 2; shadow_menu; return; fi

    mkdir -p "$(dirname "$USER_DB")"; touch "$USER_DB"
    username="trial-$(openssl rand -hex 4)"
    password=$(openssl rand -hex 8)
    exp_date=$(date -d "+24 hours" +"%Y-%m-%d")

    echo -e "${YELLOW}Creating 24-hour trial account: ${CYAN}$username${NC}"; sleep 2

    cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"
    jq '.inbounds |= map(if .protocol == "shadowsocks" and .settings.clients == null then .settings += {"clients": []} else . end) | .inbounds |= map(if .protocol == "shadowsocks" then .settings.clients += [{"method": "'$DEFAULT_METHOD'", "password": "'$password'", "email": "'$username'"}] else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

    if [ $? -eq 0 ]; then
        mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
        echo "$username:$exp_date:$password:$DEFAULT_METHOD" >> "$USER_DB"
        systemctl restart xray

        clear
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}             TRIAL SHADOWSOCKS ACCOUNT CREATED            ${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e ""
        echo -e "${YELLOW}Username (email):${NC} ${GREEN}$username${NC}"
        echo -e "${YELLOW}Password:${NC}         ${GREEN}$password${NC}"
        echo -e "${YELLOW}Method:${NC}           ${GREEN}$DEFAULT_METHOD${NC}"
        echo -e "${YELLOW}Expires in:${NC}       ${GREEN}24 Hours${NC}"
        echo -e ""
    else
        echo -e "${RED}Failed to update Xray config.${NC}"; rm -f "$XRAY_CONFIG.tmp"; mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG"; sleep 2;
    fi

    read -n 1 -s -r -p "Press any key to return to the Shadowsocks menu"
    shadow_menu
}
renew_ss_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                 RENEW SHADOWSOCKS ACCOUNT                ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/shadowsocks_users.db"
    read -p "Enter username (email) to renew: " username

    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; shadow_menu; return;
    fi

    read -p "Enter renewal duration (in days): " duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration.${NC}"; sleep 2; shadow_menu; return;
    fi

    user_data=$(grep "^${username}:" "$USER_DB")
    password=$(echo "$user_data" | cut -d: -f3)
    method=$(echo "$user_data" | cut -d: -f4)
    new_exp_date=$(date -d "+$duration days" +"%Y-%m-%d")

    sed -i "s/^${username}:.*$/${username}:${new_exp_date}:${password}:${method}/" "$USER_DB"

    echo -e "\n${GREEN}Account '$username' renewed successfully.${NC}"
    echo -e "${YELLOW}New expiration date:${NC} ${GREEN}$new_exp_date${NC}\n"

    read -n 1 -s -r -p "Press any key to return to the Shadowsocks menu"
    shadow_menu
}
delete_ss_account() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                DELETE SHADOWSOCKS ACCOUNT                ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    USER_DB="/usr/local/bin/server-manager/data/shadowsocks_users.db"

    read -p "Enter username (email) to delete: " username
    if ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; shadow_menu; return;
    fi

    read -p "Are you sure you want to delete '$username'? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        cp "$XRAY_CONFIG" "$XRAY_CONFIG.bak"
        jq '.inbounds |= map(if .protocol == "shadowsocks" then .settings.clients |= del(.[] | select(.email == "'$username'")) else . end)' "$XRAY_CONFIG" > "$XRAY_CONFIG.tmp"

        if [ $? -eq 0 ]; then
            mv "$XRAY_CONFIG.tmp" "$XRAY_CONFIG"
            sed -i "/^${username}:/d" "$USER_DB"
            systemctl restart xray
            echo -e "\n${GREEN}Account '$username' deleted successfully.${NC}\n"
        else
            echo -e "${RED}Failed to update Xray config.${NC}"; rm -f "$XRAY_CONFIG.tmp"; mv "$XRAY_CONFIG.bak" "$XRAY_CONFIG"; sleep 2;
        fi
    else
        echo -e "${YELLOW}Deletion cancelled.${NC}"
    fi

    read -n 1 -s -r -p "Press any key to return to the Shadowsocks menu"
    shadow_menu
}
check_ss_login() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                CHECK SHADOWSOCKS USER INFO               ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/shadowsocks_users.db"
    read -p "Enter username (email) to check: " username

    if [ ! -f "$USER_DB" ] || ! grep -q "^${username}:" "$USER_DB"; then
        echo -e "${RED}User '$username' not found.${NC}"; sleep 2; shadow_menu; return;
    fi

    user_data=$(grep "^${username}:" "$USER_DB")
    exp_date=$(echo "$user_data" | cut -d: -f2)
    password=$(echo "$user_data" | cut -d: -f3)
    method=$(echo "$user_data" | cut -d: -f4)

    echo -e "${YELLOW}User Details:${NC}"
    echo -e "---------------------------------------"
    echo -e "  ${CYAN}Username:${NC}  $username"
    echo -e "  ${CYAN}Password:${NC}  $password"
    echo -e "  ${CYAN}Method:${NC}    $method"
    echo -e "  ${CYAN}Expires on:${NC} $exp_date"
    echo -e "---------------------------------------"
    echo -e "\n${WHITE}Note: This check confirms the user exists in the system.${NC}"

    read -n 1 -s -r -p "Press any key to return to the Shadowsocks menu"
    shadow_menu
}
list_ss_members() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                   LIST SHADOWSOCKS MEMBERS                 ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    USER_DB="/usr/local/bin/server-manager/data/shadowsocks_users.db"

    if [ ! -f "$USER_DB" ] || ! [ -s "$USER_DB" ]; then
        echo -e "${YELLOW}No Shadowsocks users found.${NC}"
    else
        printf "%-25s | %-15s\n" "USERNAME (EMAIL)" "EXPIRES ON"
        echo -e "-------------------------------------------"
        while IFS= read -r line; do
            user=$(echo "$line" | cut -d: -f1)
            exp_date=$(echo "$line" | cut -d: -f2)
            printf "%-25s | %-15s\n" "$user" "$exp_date"
        done < "$USER_DB"
        echo -e "-------------------------------------------"
    fi

    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the Shadowsocks menu"
    shadow_menu
}

change_domain() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                   ADD/CHANGE DOMAIN                    ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    read -p "Enter your new domain name: " new_domain
    if [ -z "$new_domain" ]; then
        echo -e "${RED}No domain entered. Operation cancelled.${NC}"
        sleep 2
        system_menu
        return
    fi

    # Save the domain to a file
    echo "$new_domain" > /etc/domain

    echo -e ""
    echo -e "${GREEN}Domain successfully set to: $new_domain${NC}"
    echo -e "${YELLOW}You may need to restart services like Nginx/Xray for the change to take full effect.${NC}"
    echo -e ""

    read -n 1 -s -r -p "Press any key to return to the System menu"
    system_menu
}
change_port() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                      CHANGE PORT                       ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "This feature allows you to change the ports for SSH and Dropbear."
    echo -e "Changing ports for Xray services must be done by manually"
    echo -e "editing the /usr/local/etc/xray/config.json file."
    echo -e ""
    echo -e " ${GREEN}[1]${NC} ${WHITE}Change Port SSH${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Change Port Dropbear${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back to System Menu${NC}"
    echo -e ""
    read -p "Select an option: " choice

    case $choice in
        1)
            current_port=$(grep -E "^Port " /etc/ssh/sshd_config | awk '{print $2}')
            read -p "Enter new SSH port [current: $current_port]: " new_port
            if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
                echo -e "${RED}Invalid port number.${NC}"; sleep 2; change_port; return
            fi
            sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
            systemctl restart ssh
            echo -e "\n${GREEN}SSH port has been changed to $new_port${NC}"
            ;;
        2)
            current_port=$(grep -E "^DROPBEAR_PORT=" /etc/default/dropbear | cut -d'=' -f2)
            read -p "Enter new Dropbear port [current: $current_port]: " new_port
            if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
                echo -e "${RED}Invalid port number.${NC}"; sleep 2; change_port; return
            fi
            sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=$new_port/" /etc/default/dropbear
            systemctl restart dropbear
            echo -e "\n${GREEN}Dropbear port has been changed to $new_port${NC}"
            ;;
        0)
            system_menu
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac

    sleep 3
    system_menu
}
autoboot_menu() { echo "Function not implemented"; sleep 2; system_menu; }
backup_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                      BACKUP MENU                       ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    BACKUP_ROOT="/root/backups"
    TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
    BACKUP_DIR="$BACKUP_ROOT/server-manager-$TIMESTAMP"
    BACKUP_FILE="$BACKUP_ROOT/server-manager-backup-$TIMESTAMP.tar.gz"

    echo -e "${YELLOW}Creating backup directory...${NC}"
    mkdir -p "$BACKUP_DIR/xray"
    mkdir -p "$BACKUP_DIR/ssh"
    mkdir -p "$BACKUP_DIR/dropbear"
    mkdir -p "$BACKUP_DIR/script_data"

    echo -e "${YELLOW}Copying configuration files...${NC}"
    cp -r /usr/local/bin/server-manager/data/* "$BACKUP_DIR/script_data/"
    cp /usr/local/etc/xray/config.json "$BACKUP_DIR/xray/"
    cp /etc/ssh/sshd_config "$BACKUP_DIR/ssh/"
    cp /etc/default/dropbear "$BACKUP_DIR/dropbear/"

    echo -e "${YELLOW}Creating compressed backup file...${NC}"
    tar -czf "$BACKUP_FILE" -C "$BACKUP_ROOT" "server-manager-$TIMESTAMP"

    # Clean up the temporary directory
    rm -rf "$BACKUP_DIR"

    if [ -f "$BACKUP_FILE" ]; then
        echo -e ""
        echo -e "${GREEN}Backup created successfully!${NC}"
        echo -e "${WHITE}Your backup file is located at:${NC} ${CYAN}$BACKUP_FILE${NC}"
        echo -e ""
    else
        echo -e "${RED}Backup failed!${NC}"
    fi

    read -n 1 -s -r -p "Press any key to return to the System menu"
    system_menu
}
restore_menu() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                      RESTORE MENU                      ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""

    read -p "Enter the full path to the backup file (.tar.gz): " backup_file

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: Backup file not found at '$backup_file'${NC}"
        sleep 2
        system_menu
        return
    fi

    echo -e "${YELLOW}This will overwrite all current configurations with the backup data.${NC}"
    read -p "Are you sure you want to proceed? (y/n): " choice

    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Restore cancelled.${NC}"
        sleep 2
        system_menu
        return
    fi

    RESTORE_DIR=$(mktemp -d)

    echo -e "${YELLOW}Extracting backup file...${NC}"
    tar -xzf "$backup_file" -C "$RESTORE_DIR"

    # Find the actual backup directory inside the temp dir
    inner_dir=$(find "$RESTORE_DIR" -mindepth 1 -maxdepth 1 -type d)

    if [ -z "$inner_dir" ]; then
        echo -e "${RED}Could not find data in the backup file.${NC}"; rm -rf "$RESTORE_DIR"; sleep 2; system_menu; return;
    fi

    echo -e "${YELLOW}Restoring files...${NC}"
    # Use -a flag to preserve permissions, and add error handling
    cp -a "$inner_dir/script_data/"* /usr/local/bin/server-manager/data/ && \
    cp -a "$inner_dir/xray/config.json" /usr/local/etc/xray/ && \
    cp -a "$inner_dir/ssh/sshd_config" /etc/ssh/ && \
    cp -a "$inner_dir/dropbear/dropbear" /etc/default/ && \
    echo -e "${GREEN}Files restored successfully!${NC}" || \
    { echo -e "${RED}An error occurred during file restoration.${NC}"; rm -rf "$RESTORE_DIR"; sleep 3; system_menu; return; }

    rm -rf "$RESTORE_DIR"

    echo -e ""
    echo -e "${YELLOW}Restore complete. It is highly recommended to restart all services or reboot the system now.${NC}"
    echo -e ""

    read -n 1 -s -r -p "Press any key to return to the System menu"
    system_menu
}
webmin_menu() { echo "Function not implemented"; sleep 2; system_menu; }
limit_bandwidth() { echo "Function not implemented"; sleep 2; system_menu; }
check_usage() { echo "Function not implemented"; sleep 2; system_menu; }
restart_services() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                     RESTART SERVICES                     ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e " ${GREEN}[1]${NC} ${WHITE}Restart Xray Service${NC}"
    echo -e " ${GREEN}[2]${NC} ${WHITE}Restart Nginx Service${NC}"
    echo -e " ${GREEN}[3]${NC} ${WHITE}Restart SSH Service${NC}"
    echo -e " ${GREEN}[0]${NC} ${WHITE}Back to System Menu${NC}"
    echo -e ""
    read -p "Select a service to restart: " choice

    case $choice in
        1) systemctl restart xray; echo "Xray restarted." ;;
        2) systemctl restart nginx; echo "Nginx restarted." ;;
        3) systemctl restart ssh; echo "SSH restarted." ;;
        0) system_menu ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac

    sleep 2
    system_menu
}
reboot_system() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                      REBOOT SYSTEM                       ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    read -p "Are you sure you want to reboot the server? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Rebooting now...${NC}"
        sleep 3
        reboot
    else
        echo -e "${YELLOW}Reboot cancelled.${NC}"
        sleep 2
        system_menu
    fi
}

vps_info() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                  VPS INFORMATION                       ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${YELLOW}OS:${NC}             ${GREEN}$OS${NC}"
    echo -e "${YELLOW}Kernel:${NC}         ${GREEN}$KERNEL${NC}"
    echo -e "${YELLOW}Hostname:${NC}       ${GREEN}$HOSTNAME${NC}"
    echo -e "${YELLOW}Uptime:${NC}         ${GREEN}$UPTIME${NC}"
    echo -e ""
    echo -e "${YELLOW}CPU Model:${NC}      ${GREEN}$CPU_MODEL${NC}"
    echo -e "${YELLOW}CPU Cores:${NC}      ${GREEN}$CPU_CORES${NC}"
    echo -e "${YELLOW}Memory Usage:${NC}   ${GREEN}$MEMORY${NC}"
    echo -e "${YELLOW}Disk Usage:${NC}     ${GREEN}$DISK${NC}"
    echo -e ""
    echo -e "${YELLOW}Public IP:${NC}      ${GREEN}$IP${NC}"
    echo -e "${YELLOW}Domain:${NC}         ${GREEN}$(if [ -f /etc/domain ]; then cat /etc/domain; else echo "Not set"; fi)${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the Main menu"
    main_menu
}
bill_all_exp() { echo "Function not implemented"; sleep 2; main_menu; }
backup_restore_menu() { echo "Function not implemented"; sleep 2; main_menu; }
change_password() { echo "Function not implemented"; sleep 2; main_menu; }
cert_ssl() { echo "Function not implemented"; sleep 2; main_menu; }
about() {
    clear
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}                      ABOUT THIS SCRIPT                   ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}Server Management Script${NC}"
    echo -e "${GREEN}Version: 2.0${NC}"
    echo -e ""
    echo -e "${YELLOW}This script was developed to provide an easy-to-use,${NC}"
    echo -e "${YELLOW}menu-driven interface for managing common server tasks${NC}"
    echo -e "${YELLOW}and VPN/proxy services.${NC}"
    echo -e ""
    echo -e "${CYAN}Features implemented by Jules, your AI assistant.${NC}"
    echo -e ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Press any key to return to the Main menu"
    main_menu
}
bot_notif() { echo "Function not implemented"; sleep 2; main_menu; }
bot_panel() { echo "Function not implemented"; sleep 2; main_menu; }

# Check dependencies and start the script
check_dependencies
main_menu
