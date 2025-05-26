#!/bin/bash

# CyberSentinel Access Management Installation Script
# Author: CyberSentinel Security Team

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITHUB_REPO="https://raw.githubusercontent.com/Prajwal3112/SentinelEdge/main"
SERVICE_VERSION="v4.0.0"
INSTALL_LOG="/opt/CyberSentinel_install.log"
SERVICE_NAME="CyberSentinel Access Management"

# Progress tracking
TOTAL_STEPS=8
CURRENT_STEP=0

# Function to show progress
show_progress() {
    ((CURRENT_STEP++))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${BLUE}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} [$percent%] $1"
}

print_info() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Function to check if port is in use
check_port() {
    local port=$1
    netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "
}

# Function to get server IP
get_server_ip() {
    SERVER_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
    [ -z "$SERVER_IP" ] && SERVER_IP=$(hostname -I | awk '{print $1}')
    [ -z "$SERVER_IP" ] && { print_error "Could not detect server IP"; exit 1; }
}

# Function to check system requirements
check_requirements() {
    show_progress "Checking system requirements"
    
    # Check privileges
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_error "Root privileges required"
        exit 1
    fi
    
    # Check disk space (minimum 2GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    [ "$available_space" -lt 2097152 ] && print_warning "Low disk space detected"
    
    # Check required commands
    for cmd in curl git docker; do
        command -v "$cmd" &> /dev/null || { print_error "Required: $cmd"; exit 1; }
    done
    
    print_info "System requirements satisfied"
}

# Function to check port availability
check_ports() {
    show_progress "Verifying port availability"
    
    local ports=(80 443 2222)
    local ports_in_use=()
    
    for port in "${ports[@]}"; do
        check_port "$port" && ports_in_use+=("$port")
    done
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        print_error "Ports in use: ${ports_in_use[*]}"
        exit 1
    fi
    
    print_info "All required ports available"
}

# Function to cleanup existing installation
cleanup_existing() {
    show_progress "Cleaning existing installation"
    
    local containers=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local found_containers=()
    
    for container in "${containers[@]}"; do
        docker ps -a --format '{{.Names}}' | grep -q "^${container}$" && found_containers+=("$container")
    done
    
    if [ ${#found_containers[@]} -gt 0 ]; then
        print_warning "Removing existing containers: ${found_containers[*]}"
        for container in "${found_containers[@]}"; do
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        done
    fi
    
    [ -d "/opt/jumpserver" ] && sudo rm -rf /opt/jumpserver
    print_info "Environment cleaned"
}

# Function to install service
install_service() {
    show_progress "Installing core service components"
    
    sudo mkdir -p /opt && cd /opt
    sudo touch "$INSTALL_LOG" && sudo chmod 666 "$INSTALL_LOG"
    
    print_info "Downloading service repository..."
    sudo git clone https://github.com/jumpserver/jumpserver.git > /dev/null 2>&1 || {
        print_error "Repository download failed"
        exit 1
    }
    
    print_info "Installing service components (this may take several minutes)..."
    curl -sSL "https://github.com/jumpserver/jumpserver/releases/download/$SERVICE_VERSION/quick_start.sh" | sudo bash > "$INSTALL_LOG" 2>&1 || {
        print_error "Installation failed. Check: $INSTALL_LOG"
        exit 1
    }
    
    print_info "Core installation completed"
}

# Function to wait for services
wait_for_services() {
    show_progress "Starting service components"
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker ps | grep -q "jms_core" && docker ps | grep -q "jms_web"; then
            print_info "All service components active"
            sleep 5
            return 0
        fi
        
        echo -n "."
        sleep 10
        ((attempt++))
    done
    
    print_error "Service startup timeout. Check: $INSTALL_LOG"
    exit 1
}

# Function to download branding assets
download_branding() {
    show_progress "Applying CyberSentinel branding"
    
    local logo_files=("125_x_18.png" "30_x_40.png" "front_logo.png" "favicon_logo.ico")
    local temp_dir="/tmp/cybersentinel_branding"
    
    mkdir -p "$temp_dir" && cd "$temp_dir"
    
    for logo in "${logo_files[@]}"; do
        curl -sSL -o "$logo" "$GITHUB_REPO/$logo" || {
            print_warning "Branding download failed - continuing with default"
            return 1
        }
    done
    
    print_info "Branding assets downloaded"
    return 0
}

# Function to apply branding
apply_branding() {
    show_progress "Configuring brand assets"
    
    local temp_dir="/tmp/cybersentinel_branding"
    
    docker ps | grep -q "jms_core" || {
        print_error "Core service not available"
        return 1
    }
    
    # Apply branding
    docker cp "$temp_dir/125_x_18.png" jms_core:/opt/jumpserver/apps/static/img/logo_text_white.png 2>/dev/null || true
    docker cp "$temp_dir/30_x_40.png" jms_core:/opt/jumpserver/apps/static/img/logo.png 2>/dev/null || true
    docker cp "$temp_dir/front_logo.png" jms_core:/opt/jumpserver/apps/static/img/login_image.png 2>/dev/null || true
    docker cp "$temp_dir/favicon_logo.ico" jms_core:/opt/jumpserver/apps/static/img/facio.ico 2>/dev/null || true
    
    rm -rf "$temp_dir"
    print_info "Branding applied successfully"
}

# Function to restart services
restart_services() {
    show_progress "Finalizing configuration"
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    
    docker restart "${services[@]}" > /dev/null 2>&1 || print_warning "Some services may need manual restart"
    sleep 15
    print_info "Services restarted"
}

# Function to verify installation
verify_installation() {
    show_progress "Verifying installation"
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local running_services=0
    
    for service in "${services[@]}"; do
        docker ps | grep -q "$service" && ((running_services++))
    done
    
    if [ $running_services -eq ${#services[@]} ]; then
        print_info "All service components verified"
    else
        print_warning "$running_services/${#services[@]} components active"
    fi
    
    # Quick web check
    sleep 5
    curl -sSf "http://localhost" > /dev/null 2>&1 && print_info "Web interface ready" || print_warning "Web interface initializing"
}

# Function to show access information
show_access_info() {
    echo ""
    echo "============================================"
    echo "  $SERVICE_NAME - Installation Complete"
    echo "============================================"
    echo ""
    echo "Access Information:"
    echo "  URL: http://$SERVER_IP"
    echo "  Username: admin"
    echo "  Password: ChangeMe"
    echo ""
    echo "Important:"
    echo "  • Change default password immediately"
    echo "  • Installation logs: $INSTALL_LOG"
    echo ""
    echo "Active Components: $(docker ps --format '{{.Names}}' | grep jms_ | wc -l)/7"
    echo "============================================"
}

# Main installation flow
main() {
    echo ""
    echo "============================================"
    echo "  $SERVICE_NAME - Installation"
    echo "============================================"
    echo ""
    
    get_server_ip
    check_requirements
    check_ports
    cleanup_existing
    install_service
    wait_for_services
    
    if download_branding; then
        apply_branding
        restart_services
    else
        print_warning "Continuing with default branding"
    fi
    
    verify_installation
    show_access_info
    
    echo ""
    print_info "Installation completed successfully!"
}

# Error handling
trap 'print_error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
