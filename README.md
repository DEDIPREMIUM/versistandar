# Server Management Script

A comprehensive server management script for Ubuntu 18.04, 20.04, and Debian systems. This script provides a user-friendly interface to manage various aspects of your server, including SSH, VMESS, VLESS, Trojan, and Shadowsocks services.

![Server Management Script](https://i.imgur.com/example.png)

## Features

- **System Information Display**: Shows OS, uptime, hostname, date, time, IP, and domain
- **Account Management**: Create, renew, and delete accounts for various services
- **Server Status Monitoring**: Monitor the status of SSH, Nginx, Xray, and other services
- **Menu-Based Interface**: Easy-to-use menu system for all operations
- **Performance Tools**: Speedtest, cache clearing, and system optimization
- **Security Features**: SSL certificate management, password changes, and more

## Supported Services

- SSH/OpenVPN
- VMESS WS/GRPC
- VLESS WS/GRPC
- Trojan WS/GRPC
- Shadowsocks WS/GRPC

## Requirements

- Ubuntu 18.04 LTS
- Ubuntu 20.04 LTS
- Debian (tested on Debian 10 and 11)
- Root access

## Installation

### One-Command Installation

You can install the Server Management Script with a single command:

```bash
wget -O install.sh https://raw.githubusercontent.com/yourusername/server-manager/main/install.sh && chmod +x install.sh && sudo bash install.sh
```

Or if you have the files locally:

```bash
chmod +x install.sh && sudo bash install.sh
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/server-manager.git
   ```

2. Navigate to the directory:
   ```bash
   cd server-manager
   ```

3. Make the installation script executable:
   ```bash
   chmod +x install.sh
   ```

4. Run the installation script:
   ```bash
   sudo bash install.sh
   ```

## Usage

After installation, you can run the script using the command:

```bash
servermgr
```

This will open the main menu of the Server Management Script, where you can navigate through various options.

## Main Menu Options

1. **SSH Menu**: Manage SSH accounts and settings
2. **VMESS Menu**: Manage VMESS accounts and settings
3. **VLESS Menu**: Manage VLESS accounts and settings
4. **Trojan Menu**: Manage Trojan accounts and settings
5. **Shadow Menu**: Manage Shadowsocks accounts and settings
6. **System Menu**: Access system-related settings
7. **VPS Info**: Display detailed VPS information
8. **Bill All Exp**: Manage expired accounts
9. **Autoboot**: Configure autoboot settings
10. **Speedtest**: Test server network speed
11. **Running**: View running services
12. **Speedtest**: Alternative speedtest option
13. **Clear Cache**: Clear system cache
14. **Create Slow**: Create slow DNS (not implemented)
15. **Backup/Restore**: Backup and restore system settings
16. **Passwd VPS**: Change VPS password
17. **Restart**: Restart services
18. **Domain**: Manage domain settings
19. **Cert SSL**: Manage SSL certificates
20. **About**: Display information about the script
21. **Clear Cache**: Alternative cache clearing option
22. **Bot Notif**: Configure bot notifications
23. **Update Script**: Update the script to the latest version
24. **Bot Panel**: Access bot panel settings

## Customization

You can customize the script by editing the `/usr/local/bin/server-manager/server_manager.sh` file. Make sure to backup the original file before making any changes.

## Uninstallation

To uninstall the Server Management Script, run the following command:

```bash
sudo rm -rf /usr/local/bin/server-manager /usr/local/bin/servermgr /etc/systemd/system/server-manager.service
sudo systemctl daemon-reload
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Thanks to all contributors who have helped to improve this script
- Special thanks to the open-source community for providing the tools and libraries used in this project