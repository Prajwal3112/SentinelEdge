#!/bin/bash

# Jumpserver Installation Script with Custom Branding
# Author: Auto-generated script for Docker-based setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main"
JUMPSERVER_VERSION="v4.0.0"
INSTALL_LOG="/opt/CyberSentinel_install.log"

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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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
    
    # Check available disk space (minimum 2GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 2097152 ]; then
        print_warning "Low disk space detected. Jumpserver requires at least 2GB free space"
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

# Function to check port availability
check_ports() {
    print_step "Checking port availability..."
    
    local ports=(80 443 2222)
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

# Function to cleanup existing installation
cleanup_existing() {
    print_step "Checking for existing Jumpserver installation..."
    
    # Check for existing containers
    local containers=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local found_containers=()
    
    for container in "${containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            found_containers+=("$container")
        fi
    done
    
    if [ ${#found_containers[@]} -gt 0 ]; then
        print_warning "Found existing Jumpserver containers: ${found_containers[*]}"
        echo -n "Do you want to remove them and continue? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            print_info "Removing existing containers..."
            for container in "${found_containers[@]}"; do
                docker stop "$container" 2>/dev/null || true
                docker rm "$container" 2>/dev/null || true
            done
            print_info "✓ Existing containers removed"
        else
            print_error "Installation cancelled"
            exit 1
        fi
    fi
    
    # Clean up existing jumpserver directory
    if [ -d "/opt/jumpserver" ]; then
        print_warning "Found existing Jumpserver directory at /opt/jumpserver"
        sudo rm -rf /opt/jumpserver
        print_info "✓ Existing directory cleaned"
    fi
}

# Function to install Jumpserver
install_jumpserver() {
    print_step "Installing Jumpserver..."
    
    # Create installation directory
    sudo mkdir -p /opt
    cd /opt
    
    # Clone Jumpserver repository
    print_info "Cloning Jumpserver repository..."
    if ! sudo git clone https://github.com/jumpserver/jumpserver.git > /dev/null 2>&1; then
        print_error "Failed to clone Jumpserver repository"
        exit 1
    fi
    
    # Create log file
    sudo touch "$INSTALL_LOG"
    sudo chmod 666 "$INSTALL_LOG"
    
    # Run quick start installation
    print_info "Running Jumpserver installation (this may take several minutes)..."
    print_info "Installation logs are being written to: $INSTALL_LOG"
    
    if ! curl -sSL "https://github.com/jumpserver/jumpserver/releases/download/$JUMPSERVER_VERSION/quick_start.sh" | sudo bash > "$INSTALL_LOG" 2>&1; then
        print_error "Jumpserver installation failed. Check logs at: $INSTALL_LOG"
        exit 1
    fi
    
    print_info "✓ Jumpserver installation completed"
}

# Function to wait for services
wait_for_services() {
    print_step "Waiting for Jumpserver services to start..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps | grep -q "jms_core" && docker ps | grep -q "jms_web"; then
            print_info "✓ Jumpserver services are running"
            sleep 5  # Additional wait for full initialization
            return 0
        fi
        
        print_info "Waiting for services... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_error "Services failed to start within expected time"
    print_info "You can check the logs at: $INSTALL_LOG"
    exit 1
}

# Function to download logo files
download_logos() {
    print_step "Downloading custom logos from GitHub repository..."
    
    local logo_files=("125_x_18.png" "30_x_40.png" "front_logo.png" "favicon_logo.ico")
    local temp_dir="/tmp/jumpserver_logos"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Download each logo file
    for logo in "${logo_files[@]}"; do
        print_info "Downloading $logo..."
        if ! curl -sSL -o "$logo" "$GITHUB_REPO/$logo"; then
            print_warning "Failed to download $logo from GitHub repository"
            return 1
        fi
    done
    
    print_info "✓ All logo files downloaded successfully"
    return 0
}

# Function to replace logos
replace_logos() {
    print_step "Replacing Jumpserver logos with custom branding..."
    
    local temp_dir="/tmp/jumpserver_logos"
    
    # Check if jms_core container is running
    if ! docker ps | grep -q "jms_core"; then
        print_error "jms_core container is not running"
        return 1
    fi
    
    # Replace logos
    print_info "Copying logo_text_white.png..."
    if ! docker cp "$temp_dir/125_x_18.png" jms_core:/opt/jumpserver/apps/static/img/logo_text_white.png; then
        print_warning "Failed to copy logo_text_white.png"
    fi
    
    print_info "Copying logo.png..."
    if ! docker cp "$temp_dir/30_x_40.png" jms_core:/opt/jumpserver/apps/static/img/logo.png; then
        print_warning "Failed to copy logo.png"
    fi
    
    print_info "Copying login_image.png..."
    if ! docker cp "$temp_dir/front_logo.png" jms_core:/opt/jumpserver/apps/static/img/login_image.png; then
        print_warning "Failed to copy login_image.png"
    fi
    
    print_info "Copying favicon..."
    if ! docker cp "$temp_dir/favicon_logo.ico" jms_core:/opt/jumpserver/apps/static/img/facio.ico; then
        print_warning "Failed to copy facio.ico"
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
    
    print_info "✓ Logo replacement completed"
}

# Function to restart services
restart_services() {
    print_step "Restarting Jumpserver services to apply changes..."
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    
    print_info "Restarting services..."
    if docker restart "${services[@]}" > /dev/null 2>&1; then
        print_info "✓ Services restarted successfully"
    else
        print_warning "Some services may have failed to restart"
    fi
    
    # Wait for services to be ready again
    print_info "Waiting for services to be ready..."
    sleep 15
}

# Function to verify installation
verify_installation() {
    print_step "Verifying installation..."
    
    # Check container status
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local running_services=0
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            ((running_services++))
        fi
    done
    
    if [ $running_services -eq ${#services[@]} ]; then
        print_info "✓ All Jumpserver services are running"
    else
        print_warning "Only $running_services/${#services[@]} services are running"
    fi
    
    # Check web interface
    print_info "Checking web interface availability..."
    sleep 5
    
    if curl -sSf "http://localhost" > /dev/null 2>&1; then
        print_info "✓ Web interface is accessible"
    else
        print_warning "Web interface may not be ready yet"
    fi
}

# Function to show access information
show_access_info() {
    echo ""
    echo "============================================"
    print_info "JUMPSERVER INSTALLATION COMPLETED!"
    echo "============================================"
    echo ""
    echo "Access Information:"
    echo "  Web Interface: http://$SERVER_IP"
    echo "  Username: admin"
    echo "  Password: ChangeMe"
    echo ""
    echo "Important Notes:"
    echo "  • Please change the default password after first login"
    echo "  • Custom logos have been applied"
    echo "  • Installation logs: $INSTALL_LOG"
    echo ""
    echo "Services Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep jms_ || echo "No Jumpserver containers found"
    echo ""
    echo "============================================"
}

# Main installation flow
main() {
    echo ""
    echo "============================================"
    echo "     Jumpserver Installation Script"
    echo "============================================"
    echo ""
    
    # Get server IP
    get_server_ip
    
    # Check system requirements
    check_requirements
    
    # Check port availability
    check_ports
    
    # Cleanup existing installation
    cleanup_existing
    
    # Install Jumpserver
    install_jumpserver
    
    # Wait for services to start
    wait_for_services
    
    # Download and replace logos
    if download_logos; then
        replace_logos
        restart_services
    else
        print_warning "Skipping logo replacement due to download failure"
    fi
    
    # Verify installation
    verify_installation
    
    # Show access information
    show_access_info
    
    print_info "Installation completed successfully!"
}

# Error handling
trap 'print_error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
