# CyberSentinel Edge - Integrated Privileged Access Security Suite

![CyberSentinel Banner](https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/front_logo.png)

## Enterprise-Grade PIM, PAM & PUM Solution

**One-click deployment** of our proprietary security stack:
- 🔐 **CyberSentinel Vault** (PIM) - Secrets management
- 🛡️ **CyberSentinel Asset Manager** (PAM) - Privileged access
- 👤 **CyberSentinel Cloak** (PUM) - Identity governance

## 🚀 Instant Deployment

```bash
# Full Suite (PIM+PAM+PUM)
curl -sSL https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/install-jumpserver.sh | bash

# Lightweight (PIM+PUM only)
curl -sSL https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/install_vault_keycloak.sh | bash

⚙️ Technical Specifications
Resource	Minimum	Recommended
CPU	2 cores	4 cores
Memory	4GB RAM	8GB RAM
Storage	10GB SSD	20GB SSD
OS	Ubuntu 20.04+	Ubuntu 22.04
Network	100Mbps	1Gbps
📸 Platform Overview
CyberSentinel Dashboard
Dashboard Preview

Vault Management Interface
Vault UI

Access Control Center
Access Console

🗑️ Clean Uninstallation

# Remove Full Suite
curl -sSL https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/uninstall-jumpserver.sh | bash

# Remove PIM+PUM Components
curl -sSL https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/uninstall_vault_keycloak.sh | bash

📞 Enterprise Support
24/7 Security Operations Center
✉️ response@cybersentinel.com
🔒 Security Compliance Documentation

© 2024 CyberSentinel Technologies. All Rights Reserved.
Patented technologies. Proprietary software.



## Install JumpServer
```
curl -s -o install-jumpserver.sh https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/install-jumpserver.sh && chmod +x install-jumpserver.sh && bash ./install-jumpserver.sh
```

## Uninstall JumpServer
```
curl -s -o uninstall-jumpserver.sh https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/uninstall-jumpserver.sh && chmod +x uninstall-jumpserver.sh && bash ./uninstall-jumpserver.sh
```

## Install Vault Keycloak
```
curl -s -o install_vault_keycloak.sh https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/install_vault_keycloak.sh && chmod +x install_vault_keycloak.sh && bash ./install_vault_keycloak.sh
```

## Unistall Vault Keycloak
```
curl -s -o uninstall_vault_keycloak.sh https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/uninstall_vault_keycloak.sh && chmod +x uninstall_vault_keycloak.sh && bash ./uninstall_vault_keycloak.sh
```
