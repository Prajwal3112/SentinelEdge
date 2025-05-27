#!/bin/bash

# SentinelEdge Combined Installation Script
# Components: Identity Management, Vault, and Access Management
# Author: Auto-generated script for Docker-based setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main"
SENTINELEDGE_VERSION="v4.0.0"
INSTALL_LOG="/opt/SentinelEdge_install.log"
TOTAL_STEPS=15

# Global variables
CURRENT_STEP=1
SERVER_IP=""
CLIENT_SECRET=""

# Function to print ASCII art
print_ascii_art() {
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
 ____            _   _            _ _____    _            
/ ___|  ___ _ __ | |_(_)_ __   ___| | ____|__| | __ _  ___ 
\___ \ / _ \ '_ \| __| | '_ \ / _ \ |  _| / _` |/ _` |/ _ \
 ___) |  __/ | | | |_| | | | |  __/ | |__| (_| | (_| |  __/
|____/ \___|_| |_|\__|_|_| |_|\___|_|_____\__,_|\__, |\___|
                                               |___/      
EOF
    echo -e "${NC}"
    echo -e "${BOLD}Enterprise Security Platform Installation${NC}"
    echo "=========================================="
    echo ""
}

# Function to print colored messages with step counter
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP $CURRENT_STEP/$TOTAL_STEPS]${NC} $1"
    ((CURRENT_STEP++))
}

print_progress() {
    echo -e "${CYAN}[PROGRESS]${NC} $1"
}

# Function to check if port is in use
check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to get server IP
get_server_ip() {
    print_step "Detecting server configuration..."
    SERVER_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(hostname -I | awk '{print $1}')
    fi
    if [ -z "$SERVER_IP" ]; then
        print_error "Could not detect server IP automatically"
        exit 1
    fi
    print_info "Detected Server IP: $SERVER_IP"
}

# Function to check system requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    # Check if running as root or with sudo
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_error "This script requires root privileges or sudo access"
        exit 1
    fi
    
    # Check required commands
    local required_commands=("curl" "git" "docker")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' is not installed"
            exit 1
        fi
    done
    
    print_info "✓ System requirements check passed"
}

# Function to install Docker (from vault_keycloak script)
install_docker() {
    if command -v docker &> /dev/null; then
        print_info "Docker is already installed"
        docker --version
    else
        print_progress "Installing Docker..."
        
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
    print_step "Checking for existing installations..."
    
    # Check and remove Identity Management container
    if docker ps -a | grep -q "my-keycloak"; then
        print_warning "Found existing SentinelEdge Identity container. Removing..."
        docker stop my-keycloak 2>/dev/null || true
        docker rm my-keycloak 2>/dev/null || true
    fi
    
    # Check and remove Vault container
    if docker ps -a | grep -q "dev-vault"; then
        print_warning "Found existing SentinelEdge Vault container. Removing..."
        docker stop dev-vault 2>/dev/null || true
        docker rm dev-vault 2>/dev/null || true
    fi
    
    # Check for existing Access Management containers
    local containers=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local found_containers=()
    
    for container in "${containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            found_containers+=("$container")
        fi
    done
    
    if [ ${#found_containers[@]} -gt 0 ]; then
        print_warning "Found existing SentinelEdge Access containers: ${found_containers[*]}"
        print_progress "Removing existing containers..."
        for container in "${found_containers[@]}"; do
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        done
        print_info "✓ Existing containers removed"
    fi
    
    # Clean up existing directory
    if [ -d "/opt/jumpserver" ]; then
        print_warning "Found existing SentinelEdge directory at /opt/jumpserver"
        sudo rm -rf /opt/jumpserver
        print_info "✓ Existing directory cleaned"
    fi
    
    print_info "Cleanup completed"
}

# Function to check port availability
check_ports() {
    print_step "Checking port availability..."
    
    local ports=(80 443 2222 8080 8200)
    local ports_in_use=()
    
    for port in "${ports[@]}"; do
        if check_port "$port"; then
            ports_in_use+=("$port")
        fi
    done
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        print_error "The following required ports are in use: ${ports_in_use[*]}"
        print_error "Please free these ports and try again"
        exit 1
    fi
    
    print_info "✓ All required ports are available"
}

# Function to install SentinelEdge Identity (Keycloak)
install_identity_management() {
    print_step "Installing SentinelEdge Identity Management..."
    
    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM quay.io/keycloak/keycloak:26.2.4
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=dev-mem
RUN /opt/keycloak/bin/kc.sh build
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
EOF
    
    # Build and run Identity Management
    print_progress "Building SentinelEdge Identity Docker image..."
    docker build -t my-keycloak .
    
    print_progress "Starting SentinelEdge Identity container..."
    docker run -d -p 8080:8080 \
        -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
        -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
        --name my-keycloak \
        my-keycloak
    
    # Wait for Identity Management to start
    print_progress "Waiting for SentinelEdge Identity to start (this may take a few minutes)..."
    sleep 30
    
    # Check if Identity Management is running
    for i in {1..12}; do
        if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
            print_info "SentinelEdge Identity is ready!"
            break
        else
            if [ $i -eq 12 ]; then
                print_error "SentinelEdge Identity failed to start within expected time"
                exit 1
            fi
            print_progress "Still waiting for SentinelEdge Identity... (attempt $i/12)"
            sleep 10
        fi
    done
    
    # Clean up Dockerfile
    rm -f Dockerfile
    
    print_info "✓ SentinelEdge Identity installed successfully!"
    print_info "Access SentinelEdge Identity Admin Console: http://$SERVER_IP:8080"
    print_info "Admin credentials: admin/admin"
}

# Function to show Identity Management configuration steps
show_identity_config() {
    print_step "SentinelEdge Identity configuration required..."
    echo ""
    print_info "SENTINELEDGE IDENTITY CONFIGURATION STEPS:"
    echo "=========================================="
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
    echo "=========================================="
    echo ""
}

# Function to get client secret from user
get_client_secret() {
    while true; do
        echo -n "Please paste the Client Secret from SentinelEdge Identity: "
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

# Function to install SentinelEdge Vault
install_vault() {
    print_step "Installing SentinelEdge Vault..."
    
    # Pull and run Vault
    print_progress "Pulling SentinelEdge Vault Docker image..."
    docker pull hashicorp/vault
    
    print_progress "Starting SentinelEdge Vault container..."
    docker run --cap-add=IPC_LOCK \
        -e VAULT_DEV_ROOT_TOKEN_ID=myroot \
        -p 8200:8200 \
        --name dev-vault \
        -d hashicorp/vault
    
    # Wait for Vault to start
    print_progress "Waiting for SentinelEdge Vault to start..."
    sleep 10
    
    # Check if Vault is running
    for i in {1..6}; do
        if curl -s http://localhost:8200/v1/sys/health > /dev/null 2>&1; then
            print_info "SentinelEdge Vault is ready!"
            break
        else
            if [ $i -eq 6 ]; then
                print_error "SentinelEdge Vault failed to start within expected time"
                exit 1
            fi
            print_progress "Still waiting for SentinelEdge Vault... (attempt $i/6)"
            sleep 5
        fi
    done
    
    print_info "✓ SentinelEdge Vault installed successfully!"
    print_info "Access SentinelEdge Vault: http://$SERVER_IP:8200"
    print_info "Root Token: myroot"
}

# Function to configure Vault OIDC
configure_vault_oidc() {
    print_step "Configuring SentinelEdge Vault integration..."
    
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

# Configure OIDC with Identity Management
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
    
    print_info "✓ SentinelEdge Vault integration configuration completed!"
}

# Function to install SentinelEdge Access Management
install_access_management() {
    print_step "Installing SentinelEdge Access Management..."
    
    # Create installation directory
    sudo mkdir -p /opt
    cd /opt
    
    # Clone repository
    print_progress "Cloning SentinelEdge Access repository..."
    if ! sudo git clone https://github.com/jumpserver/jumpserver.git > /dev/null 2>&1; then
        print_error "Failed to clone SentinelEdge Access repository"
        exit 1
    fi
    
    # Create log file
    sudo touch "$INSTALL_LOG"
    sudo chmod 666 "$INSTALL_LOG"
    
    # Run quick start installation
    print_progress "Running SentinelEdge Access installation (this may take several minutes)..."
    print_info "Installation logs are being written to: $INSTALL_LOG"
    
    if ! curl -sSL "https://github.com/jumpserver/jumpserver/releases/download/$SENTINELEDGE_VERSION/quick_start.sh" | sudo bash > "$INSTALL_LOG" 2>&1; then
        print_error "SentinelEdge Access installation failed. Check logs at: $INSTALL_LOG"
        exit 1
    fi
    
    print_info "✓ SentinelEdge Access installation completed"
}

# Function to wait for Access Management services
wait_for_access_services() {
    print_step "Waiting for SentinelEdge Access services to start..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps | grep -q "jms_core" && docker ps | grep -q "jms_web"; then
            print_info "✓ SentinelEdge Access services are running"
            sleep 5  # Additional wait for full initialization
            return 0
        fi
        
        print_progress "Waiting for services... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_error "Services failed to start within expected time"
    print_info "You can check the logs at: $INSTALL_LOG"
    exit 1
}

# Function to download logo files
download_logos() {
    print_step "Downloading custom branding assets..."
    
    local logo_files=("125_x_18.png" "30_x_40.png" "front_logo.png" "favicon_logo.ico")
    local temp_dir="/tmp/sentineledge_logos"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Download each logo file
    for logo in "${logo_files[@]}"; do
        print_progress "Downloading $logo..."
        if ! curl -sSL -o "$logo" "$GITHUB_REPO/$logo"; then
            print_warning "Failed to download $logo from GitHub repository"
            return 1
        fi
    done
    
    print_info "✓ All branding assets downloaded successfully"
    return 0
}

# Function to replace logos
replace_logos() {
    print_step "Applying custom branding to SentinelEdge Access..."
    
    local temp_dir="/tmp/sentineledge_logos"
    
    # Check if core container is running
    if ! docker ps | grep -q "jms_core"; then
        print_error "SentinelEdge Access core container is not running"
        return 1
    fi
    
    # Replace logos
    print_progress "Copying logo_text_white.png..."
    if ! docker cp "$temp_dir/125_x_18.png" jms_core:/opt/jumpserver/apps/static/img/logo_text_white.png; then
        print_warning "Failed to copy logo_text_white.png"
    fi
    
    print_progress "Copying logo.png..."
    if ! docker cp "$temp_dir/30_x_40.png" jms_core:/opt/jumpserver/apps/static/img/logo.png; then
        print_warning "Failed to copy logo.png"
    fi
    
    print_progress "Copying login_image.png..."
    if ! docker cp "$temp_dir/front_logo.png" jms_core:/opt/jumpserver/apps/static/img/login_image.png; then
        print_warning "Failed to copy login_image.png"
    fi
    
    print_progress "Copying favicon..."
    if ! docker cp "$temp_dir/favicon_logo.ico" jms_core:/opt/jumpserver/apps/static/img/facio.ico; then
        print_warning "Failed to copy facio.ico"
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
    
    print_info "✓ Custom branding applied successfully"
}

# Function to restart Access Management services
restart_access_services() {
    print_step "Restarting SentinelEdge Access services to apply changes..."
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    
    print_progress "Restarting services..."
    if docker restart "${services[@]}" > /dev/null 2>&1; then
        print_info "✓ Services restarted successfully"
    else
        print_warning "Some services may have failed to restart"
    fi
    
    # Wait for services to be ready again
    print_progress "Waiting for services to be ready..."
    sleep 15
}

# Function to verify complete installation
verify_installation() {
    print_step "Verifying SentinelEdge installation..."
    
    echo ""
    print_info "INSTALLATION VERIFICATION"
    echo "=========================="
    
    # Check Identity Management
    if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
        print_info "✓ SentinelEdge Identity is running and healthy"
    else
        print_error "✗ SentinelEdge Identity health check failed"
    fi
    
    # Check Vault
    if curl -s http://localhost:8200/v1/sys/health > /dev/null 2>&1; then
        print_info "✓ SentinelEdge Vault is running and healthy"
    else
        print_error "✗ SentinelEdge Vault health check failed"
    fi
    
    # Check Access Management services
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local running_services=0
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            ((running_services++))
        fi
    done
    
    if [ $running_services -eq ${#services[@]} ]; then
        print_info "✓ All SentinelEdge Access services are running"
    else
        print_warning "Only $running_services/${#services[@]} SentinelEdge Access services are running"
    fi
    
    # Check web interface
    print_progress "Checking web interface availability..."
    sleep 5
    
    if curl -sSf "http://localhost" > /dev/null 2>&1; then
        print_info "✓ SentinelEdge Access web interface is accessible"
    else
        print_warning "SentinelEdge Access web interface may not be ready yet"
    fi
}

# Function to show final access information
show_access_info() {
    echo ""
    echo "============================================"
    print_info "SENTINELEDGE INSTALLATION COMPLETED!"
    echo "============================================"
    echo ""
    echo "Access Information:"
    echo "  SentinelEdge Identity: http://$SERVER_IP:8080 (admin/admin)"
    echo "  SentinelEdge Vault: http://$SERVER_IP:8200 (Token: myroot)"
    echo "  SentinelEdge Access: http://$SERVER_IP (admin/ChangeMe)"
    echo ""
    echo "Important Notes:"
    echo "  • Please change default passwords after first login"
    echo "  • Custom branding has been applied to Access Management"
    echo "  • You can now log into Vault using OIDC authentication"
    echo "  • Installation logs: $INSTALL_LOG"
    echo ""
    echo "Services Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(jms_|my-keycloak|dev-vault)" || echo "Some containers may not be visible"
    echo ""
    echo "============================================"
}

# Main installation flow
main() {
    # Print ASCII art
    print_ascii_art
    
    # Initialize log file
    sudo touch "$INSTALL_LOG" 2>/dev/null || touch "$INSTALL_LOG"
    sudo chmod 666 "$INSTALL_LOG" 2>/dev/null || chmod 666 "$INSTALL_LOG"
    
    # Get server IP
    get_server_ip
    
    # Check system requirements
    check_requirements
    
    # Install Docker
    install_docker
    
    # Cleanup existing installations
    cleanup_containers
    
    # Check port availability
    check_ports
    
    # Install SentinelEdge Identity Management (Keycloak)
    install_identity_management
    
    # Show Identity Management configuration steps
    show_identity_config
    
    # Wait for user to configure Identity Management
    echo -n "Press Enter after completing SentinelEdge Identity configuration steps above..."
    read -r
    
    # Get client secret
    get_client_secret
    
    # Install SentinelEdge Vault
    install_vault
    
    # Configure Vault OIDC integration
    configure_vault_oidc
    
    # Install SentinelEdge Access Management (JumpServer)
    install_access_management
    
    # Wait for Access Management services to start
    wait_for_access_services
    
    # Download and apply custom branding
    if download_logos; then
        replace_logos
        restart_access_services
    else
        print_warning "Skipping branding customization due to download failure"
    fi
    
    # Verify complete installation
    verify_installation
    
    # Show final access information
    show_access_info
    
    print_info "SentinelEdge installation completed successfully!"
}

# Error handling
trap 'print_error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
