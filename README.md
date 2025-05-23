# SentinelEdge

<div align="center">
  <img src="logos/30_x_40.png" alt="SentinelEdge Logo" width="60" height="80">
  
  **Enterprise Security Platform**
  
  *Integrated Vault + Keycloak + JumpServer Solution*
  
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
  [![Security](https://img.shields.io/badge/Security-Enterprise-green.svg)](#security-features)
</div>

---

## 🚀 Quick Start

Install the complete SentinelEdge security platform with a single command:

```bash
curl -s -o install-sentineledge.sh https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/install-sentineledge.sh && chmod +x install-sentineledge.sh && bash ./install-sentineledge.sh
```

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Components](#components)
- [Configuration](#configuration)
- [Usage](#usage)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

SentinelEdge is a comprehensive enterprise security platform that combines three powerful open-source tools into a unified solution:

- **🔐 HashiCorp Vault** - Secrets management and encryption
- **🎭 Keycloak** - Identity and access management
- **🖥️ JumpServer** - Bastion host and privileged access management

This integrated platform provides organizations with a complete security infrastructure for managing secrets, identities, and privileged access in modern cloud environments.

## ✨ Features

### 🔒 Security Features
- **Centralized Secret Management** - Store, manage, and distribute secrets securely
- **Identity Federation** - Single sign-on (SSO) with OIDC/SAML support
- **Privileged Access Management** - Secure access to critical infrastructure
- **Multi-Factor Authentication** - Enhanced security with MFA support
- **Audit Logging** - Comprehensive audit trails for compliance

### 🛠️ Technical Features
- **Docker-based Deployment** - Easy installation and management
- **Automated Integration** - Pre-configured service integration
- **Custom Branding** - SentinelEdge branded interface
- **Health Monitoring** - Built-in health checks and monitoring
- **Scalable Architecture** - Designed for enterprise scalability

### 🎨 User Experience
- **Unified Interface** - Consistent user experience across platforms
- **Custom Logos** - Professional SentinelEdge branding
- **Responsive Design** - Works on desktop and mobile devices
- **Role-based Access** - Granular permission management

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SentinelEdge Platform                │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Keycloak   │  │    Vault    │  │ JumpServer  │     │
│  │   :8080     │  │   :8200     │  │    :80      │     │
│  │             │  │             │  │             │     │
│  │ Identity &  │◄─┤ Secrets &   │  │ Bastion &   │     │
│  │ Access Mgmt │  │ Encryption  │  │ Asset Mgmt  │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Docker Engine                      │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

### System Requirements
- **Operating System**: Ubuntu 18.04+ or CentOS 7+
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: 20GB free disk space
- **Network**: Internet connection for downloading components

### Software Dependencies
- **Docker**: 20.10+ (automatically installed if not present)
- **Docker Compose**: 2.0+ (automatically installed if not present)
- **Git**: For cloning repositories
- **Curl**: For downloading installation scripts

### Network Ports
The following ports need to be available:
- **8080**: Keycloak web interface
- **8200**: Vault web interface
- **80/443**: JumpServer web interface
- **2222**: JumpServer SSH service

## 🚀 Installation

### Automated Installation (Recommended)

1. **Download and run the installation script:**
   ```bash
   curl -s -o install-sentineledge.sh https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/install-sentineledge.sh && chmod +x install-sentineledge.sh && bash ./install-sentineledge.sh
   ```

2. **Follow the interactive prompts:**
   - The script will automatically install Docker and Docker Compose
   - Configure Keycloak realm and client as instructed
   - Provide the Keycloak client secret when prompted

3. **Access your services:**
   - Keycloak: `http://your-server-ip:8080`
   - Vault: `http://your-server-ip:8200`
   - JumpServer: `http://your-server-ip`

### Manual Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Prajwal3112/SentinelEdge.git
   cd SentinelEdge
   ```

2. **Make the script executable:**
   ```bash
   chmod +x install-sentineledge.sh
   ```

3. **Run the installation:**
   ```bash
   ./install-sentineledge.sh
   ```

## 🧩 Components

### 🔐 HashiCorp Vault
- **Purpose**: Centralized secrets management
- **Default Access**: `http://your-server-ip:8200`
- **Default Token**: `myroot`
- **Features**:
  - Dynamic secrets generation
  - Encryption as a service
  - Identity-based access policies
  - Audit logging

### 🎭 Keycloak
- **Purpose**: Identity and access management
- **Default Access**: `http://your-server-ip:8080`
- **Default Credentials**: `admin/admin`
- **Features**:
  - Single sign-on (SSO)
  - Social login integration
  - Multi-factor authentication
  - User federation

### 🖥️ JumpServer
- **Purpose**: Bastion host and privileged access management
- **Default Access**: `http://your-server-ip`
- **Default Credentials**: `admin/admin`
- **Features**:
  - SSH/RDP proxy
  - Session recording
  - Asset management
  - Command filtering

## ⚙️ Configuration

### Initial Setup

1. **Configure Keycloak:**
   ```bash
   # Access Keycloak admin console
   # Create a realm named "vault"
   # Create a client named "vault-client"
   # Configure OIDC settings
   ```

2. **Configure Vault:**
   ```bash
   # Access Vault UI
   # The OIDC integration is automatically configured
   # Create policies and secrets as needed
   ```

3. **Configure JumpServer:**
   ```bash
   # Access JumpServer web interface
   # Add your infrastructure assets
   # Configure user permissions
   # Set up connection protocols
   ```

### Advanced Configuration

#### Keycloak Realm Configuration
```yaml
Realm: vault
Client ID: vault-client
Client Protocol: openid-connect
Access Type: confidential
Valid Redirect URIs: http://your-server-ip:8200/*
```

#### Vault OIDC Configuration
```bash
vault write auth/oidc/config \
    oidc_discovery_url="http://your-server-ip:8080/realms/vault" \
    oidc_client_id="vault-client" \
    oidc_client_secret="YOUR_CLIENT_SECRET"
```

## 🔧 Usage

### Managing Secrets with Vault

```bash
# Set environment variable
export VAULT_ADDR='http://your-server-ip:8200'

# Login with root token
vault login myroot

# Store a secret
vault kv put secret/myapp/db password="supersecret"

# Retrieve a secret
vault kv get secret/myapp/db
```

### Managing Users with Keycloak

1. **Create Users:**
   - Access Keycloak admin console
   - Navigate to Users section
   - Add new users with appropriate roles

2. **Configure SSO:**
   - Set up identity providers
   - Configure social logins
   - Enable multi-factor authentication

### Managing Assets with JumpServer

1. **Add Assets:**
   - Navigate to Assets section
   - Add servers, databases, and applications
   - Configure connection protocols

2. **Assign Permissions:**
   - Create user groups
   - Assign asset permissions
   - Configure access policies

## 🔒 Security

### Security Best Practices

1. **Change Default Passwords:**
   ```bash
   # Change Keycloak admin password
   # Change JumpServer admin password
   # Rotate Vault root token
   ```

2. **Enable HTTPS:**
   ```bash
   # Configure SSL certificates
   # Update service configurations
   # Redirect HTTP to HTTPS
   ```

3. **Network Security:**
   ```bash
   # Configure firewall rules
   # Restrict access to management interfaces
   # Use VPN for remote access
   ```

### Compliance Features

- **Audit Logging**: All actions are logged for compliance
- **Access Control**: Role-based access control (RBAC)
- **Encryption**: Data encrypted at rest and in transit
- **Multi-Factor Authentication**: Additional security layer

## 🔄 Maintenance

### Backup Procedures

```bash
# Backup Vault data
docker exec dev-vault vault operator raft snapshot save backup.snap

# Backup Keycloak data
docker exec my-keycloak /opt/keycloak/bin/kc.sh export --file /tmp/keycloak-export.json

# Backup JumpServer data
docker exec jms_core python manage.py dumpdata > jumpserver-backup.json
```

### Update Procedures

```bash
# Update containers
docker pull hashicorp/vault:latest
docker pull quay.io/keycloak/keycloak:latest

# Restart services
docker-compose restart
```

## 🗑️ Uninstallation

### Complete Removal

```bash
# Download and run uninstallation script
curl -s -o uninstall-sentineledge.sh https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main/uninstall-sentineledge.sh && chmod +x uninstall-sentineledge.sh && bash ./uninstall-sentineledge.sh
```

### Selective Removal

```bash
# Remove only specific components
./uninstall-sentineledge.sh --keycloak    # Remove only Keycloak
./uninstall-sentineledge.sh --vault       # Remove only Vault
./uninstall-sentineledge.sh --jumpserver  # Remove only JumpServer
```

## 🐛 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check port usage
netstat -tuln | grep :8080
netstat -tuln | grep :8200

# Stop conflicting services
sudo systemctl stop apache2
sudo systemctl stop nginx
```

#### Container Issues
```bash
# Check container status
docker ps -a

# View container logs
docker logs my-keycloak
docker logs dev-vault
docker logs jms_core

# Restart containers
docker restart my-keycloak dev-vault jms_core
```

#### Permission Issues
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker

# Fix file permissions
sudo chown -R $USER:$USER /opt/jumpserver
```

### Log Locations

- **Installation Log**: `/opt/CyberSentinel_install.log`
- **Docker Logs**: `docker logs <container_name>`
- **System Logs**: `/var/log/syslog`

### Support Resources

- **GitHub Issues**: [Report bugs and request features](https://github.com/Prajwal3112/SentinelEdge/issues)
- **Documentation**: [Official documentation](https://github.com/Prajwal3112/SentinelEdge/wiki)
- **Community**: [Join our discussions](https://github.com/Prajwal3112/SentinelEdge/discussions)

## 📊 Monitoring

### Health Checks

```bash
# Check service health
curl -s http://localhost:8080/health/ready  # Keycloak
curl -s http://localhost:8200/v1/sys/health # Vault
curl -s http://localhost/api/health/        # JumpServer
```

### Performance Monitoring

```bash
# Monitor resource usage
docker stats

# Check disk usage
df -h

# Monitor network
netstat -tuln
```

## 🤝 Contributing

We welcome contributions to SentinelEdge! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Fork the repository
git clone https://github.com/your-username/SentinelEdge.git
cd SentinelEdge

# Create a feature branch
git checkout -b feature/your-feature

# Make your changes and commit
git commit -am "Add your feature"

# Push to your fork
git push origin feature/your-feature

# Create a pull request
```

### Code Standards

- Follow shell scripting best practices
- Include error handling and logging
- Test on multiple Linux distributions
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **HashiCorp** for Vault
- **Red Hat** for Keycloak
- **JumpServer Team** for JumpServer
- **Docker** for containerization platform
- **Open Source Community** for continuous support

## 📞 Support

For support and questions:

- **GitHub Issues**: [Create an issue](https://github.com/Prajwal3112/SentinelEdge/issues)
- **Email**: support@sentineledge.com
- **Documentation**: [Wiki](https://github.com/Prajwal3112/SentinelEdge/wiki)

---

<div align="center">
  <p><strong>SentinelEdge - Securing Your Digital Edge</strong></p>
  <p>Made with ❤️ for the open source community</p>
</div>
