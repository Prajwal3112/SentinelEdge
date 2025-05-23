#!/bin/bash

# Vault + Keycloak Integration Installation Script
# Author: Auto-generated script for Docker-based setup

set -e

# Colors for output (basic)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if port is in use
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to get server IP
get_server_ip() {
    SERVER_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    if [ -z "$SERVER_IP" ]; then
        print_error "Could not detect server IP automatically"
        exit 1
    fi
    print_info "Detected Server IP: $SERVER_IP"
}

# Function to install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_info "Docker is already installed"
        docker --version
    else
        print_info "Installing Docker..."
        
        # Update package index
        sudo apt-get update
        
        # Install required packages
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Set up stable repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        
        print_info "Docker installed successfully"
        print_warning "You may need to log out and log back in for docker group permissions to take effect"
    fi
}

# Function to cleanup existing containers
cleanup_containers() {
    print_info "Checking for existing containers..."
    
    # Check and remove Keycloak container
    if docker ps -a | grep -q "my-keycloak"; then
        print_warning "Found existing Keycloak container. Removing..."
        docker stop my-keycloak 2>/dev/null || true
        docker rm my-keycloak 2>/dev/null || true
    fi
    
    # Check and remove Vault container
    if docker ps -a | grep -q "dev-vault"; then
        print_warning "Found existing Vault container. Removing..."
        docker stop dev-vault 2>/dev/null || true
        docker rm dev-vault 2>/dev/null || true
    fi
    
    print_info "Cleanup completed"
}

# Function to install Keycloak
install_keycloak() {
    print_info "Installing Keycloak..."
    
    # Check if port 8080 is free
    if check_port 8080; then
        print_error "Port 8080 is already in use. Please free the port and try again."
        exit 1
    fi
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM quay.io/keycloak/keycloak:26.2.4
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=dev-mem
RUN /opt/keycloak/bin/kc.sh build
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
EOF
    
    # Build and run Keycloak
    print_info "Building Keycloak Docker image..."
    docker build -t my-keycloak .
    
    print_info "Starting Keycloak container..."
    docker run -d -p 8080:8080 \
        -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
        -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
        --name my-keycloak \
        my-keycloak
    
    # Wait for Keycloak to start
    print_info "Waiting for Keycloak to start (this may take a few minutes)..."
    sleep 30
    
    # Check if Keycloak is running
    for i in {1..12}; do
        if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
            print_info "Keycloak is ready!"
            break
        else
            if [ $i -eq 12 ]; then
                print_error "Keycloak failed to start within expected time"
                exit 1
            fi
            print_info "Still waiting for Keycloak... (attempt $i/12)"
            sleep 10
        fi
    done
    
    # Clean up Dockerfile
    rm -f Dockerfile
    
    print_info "Keycloak installed successfully!"
    print_info "Access Keycloak Admin Console: http://$SERVER_IP:8080"
    print_info "Admin credentials: admin/admin"
}

# Function to show Keycloak configuration steps
show_keycloak_config() {
    echo ""
    print_info "KEYCLOAK CONFIGURATION STEPS:"
    echo "======================================"
    echo "1. Open browser and go to: http://$SERVER_IP:8080"
    echo "2. Login with credentials: admin/admin"
    echo "3. Create a new realm called: vault"
    echo "4. In the 'vault' realm, create a new client:"
    echo "   - Client ID: vault-client"
    echo "   - Client type: OpenID Connect"
    echo "   - Client authentication: ON"
    echo "5. In Client Settings:"
    echo "   - Root URL: http://$SERVER_IP:8200/ui/vault/auth/oidc/oidc/callback"
    echo "   - Valid redirect URIs: http://$SERVER_IP:8200/*"
    echo "6. Go to 'Credentials' tab and copy the 'Client Secret'"
    echo "======================================"
    echo ""
}

# Function to get client secret from user
get_client_secret() {
    while true; do
        echo -n "Please paste the Client Secret from Keycloak: "
        read -r CLIENT_SECRET
        
        if [ -z "$CLIENT_SECRET" ]; then
            print_error "Client secret cannot be empty. Please try again."
            continue
        fi
        
        # Basic validation - check if it looks like a UUID or secret
        if [[ ${#CLIENT_SECRET} -lt 10 ]]; then
            print_error "Client secret seems too short. Please verify and try again."
            continue
        fi
        
        print_info "Client secret received"
        break
    done
}

# Function to install Vault
install_vault() {
    print_info "Installing Vault..."
    
    # Check if port 8200 is free
    if check_port 8200; then
        print_error "Port 8200 is already in use. Please free the port and try again."
        exit 1
    fi
    
    # Pull and run Vault
    print_info "Pulling Vault Docker image..."
    docker pull hashicorp/vault
    
    print_info "Starting Vault container..."
    docker run --cap-add=IPC_LOCK \
        -e VAULT_DEV_ROOT_TOKEN_ID=myroot \
        -p 8200:8200 \
        --name dev-vault \
        -d hashicorp/vault
    
    # Wait for Vault to start
    print_info "Waiting for Vault to start..."
    sleep 10
    
    # Check if Vault is running
    for i in {1..6}; do
        if curl -s http://localhost:8200/v1/sys/health > /dev/null 2>&1; then
            print_info "Vault is ready!"
            break
        else
            if [ $i -eq 6 ]; then
                print_error "Vault failed to start within expected time"
                exit 1
            fi
            print_info "Still waiting for Vault... (attempt $i/6)"
            sleep 5
        fi
    done
    
    print_info "Vault installed successfully!"
    print_info "Access Vault: http://$SERVER_IP:8200"
    print_info "Root Token: myroot"
}

# Function to configure Vault OIDC
configure_vault_oidc() {
    print_info "Configuring Vault OIDC integration..."
    
    # Create configuration script for Vault
    cat > vault_config.sh << EOF
#!/bin/sh
export VAULT_ADDR='http://127.0.0.1:8200'
vault login myroot

# Enable OIDC auth method
vault auth enable oidc

# Create reader policy
cat <<POLICY > reader-policy.hcl
path "secret/*" {
  capabilities = ["read", "list"]
}
POLICY

vault policy write reader reader-policy.hcl

# Configure OIDC with Keycloak
vault write auth/oidc/config \\
    oidc_discovery_url="http://$SERVER_IP:8080/realms/vault" \\
    oidc_client_id="vault-client" \\
    oidc_client_secret="$CLIENT_SECRET" \\
    default_role="reader"

# Create OIDC role
vault write auth/oidc/role/reader \\
    bound_audiences="vault-client" \\
    allowed_redirect_uris="http://$SERVER_IP:8200/ui/vault/auth/oidc/oidc/callback" \\
    user_claim="sub" \\
    policies="reader"

echo "OIDC configuration completed successfully!"
EOF
    
    # Copy script to container and execute
    docker cp vault_config.sh dev-vault:/tmp/vault_config.sh
    docker exec dev-vault chmod +x /tmp/vault_config.sh
    docker exec dev-vault /tmp/vault_config.sh
    
    # Clean up
    rm -f vault_config.sh
    
    print_info "Vault OIDC configuration completed!"
}

# Function to verify installation
verify_installation() {
    echo ""
    print_info "INSTALLATION VERIFICATION"
    echo "=========================="
    
    # Check Keycloak
    if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
        print_info "✓ Keycloak is running and healthy"
    else
        print_error "✗ Keycloak health check failed"
    fi
    
    # Check Vault
    if curl -s http://localhost:8200/v1/sys/health > /dev/null 2>&1; then
        print_info "✓ Vault is running and healthy"
    else
        print_error "✗ Vault health check failed"
    fi
    
    echo ""
    print_info "ACCESS INFORMATION:"
    echo "==================="
    echo "Keycloak Admin: http://$SERVER_IP:8080 (admin/admin)"
    echo "Vault UI: http://$SERVER_IP:8200 (Token: myroot)"
    echo ""
    print_info "You can now log into Vault using OIDC authentication through Keycloak!"
}

# Main installation flow
main() {
    echo "Vault + Keycloak Integration Installation Script"
    echo "==============================================="
    echo ""
    
    # Get server IP
    get_server_ip
    
    # Install Docker
    install_docker
    
    # Cleanup existing containers
    cleanup_containers
    
    # Install Keycloak
    install_keycloak
    
    # Show Keycloak configuration steps
    show_keycloak_config
    
    # Wait for user to configure Keycloak
    echo -n "Press Enter after completing Keycloak configuration steps above..."
    read -r
    
    # Get client secret
    get_client_secret
    
    # Install Vault
    install_vault
    
    # Configure Vault OIDC
    configure_vault_oidc
    
    # Verify installation
    verify_installation
    
    print_info "Installation completed successfully!"
}

# Run main function
main
