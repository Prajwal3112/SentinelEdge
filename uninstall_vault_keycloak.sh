#!/bin/bash

# Vault + Keycloak Integration Uninstallation Script
# Author: Auto-generated script for Docker-based cleanup

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

# Function to check if container exists
container_exists() {
    local container_name=$1
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0  # Container exists
    else
        return 1  # Container doesn't exist
    fi
}

# Function to check if container is running
container_running() {
    local container_name=$1
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0  # Container is running
    else
        return 1  # Container is not running
    fi
}

# Function to remove Keycloak
remove_keycloak() {
    print_info "Removing Keycloak..."
    
    if container_exists "my-keycloak"; then
        if container_running "my-keycloak"; then
            print_info "Stopping Keycloak container..."
            docker stop my-keycloak
        fi
        
        print_info "Removing Keycloak container..."
        docker rm my-keycloak
        print_info "✓ Keycloak container removed successfully"
    else
        print_warning "Keycloak container 'my-keycloak' not found"
    fi
    
    # Remove Keycloak image if exists
    if docker images | grep -q "my-keycloak"; then
        print_info "Removing Keycloak image..."
        docker rmi my-keycloak 2>/dev/null || print_warning "Could not remove Keycloak image"
    fi
}

# Function to remove Vault
remove_vault() {
    print_info "Removing Vault..."
    
    if container_exists "dev-vault"; then
        if container_running "dev-vault"; then
            print_info "Stopping Vault container..."
            docker stop dev-vault
        fi
        
        print_info "Removing Vault container..."
        docker rm dev-vault
        print_info "✓ Vault container removed successfully"
    else
        print_warning "Vault container 'dev-vault' not found"
    fi
}

# Function to show container status
show_container_status() {
    echo ""
    print_info "CURRENT CONTAINER STATUS:"
    echo "========================="
    
    echo "All containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(my-keycloak|dev-vault|NAMES)" || echo "No Vault/Keycloak containers found"
    
    echo ""
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(my-keycloak|dev-vault|NAMES)" || echo "No Vault/Keycloak containers running"
}

# Function to cleanup Docker images
cleanup_images() {
    echo ""
    read -p "Do you want to remove related Docker images as well? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning up Docker images..."
        
        # Remove Keycloak image
        if docker images | grep -q "quay.io/keycloak/keycloak"; then
            print_info "Removing Keycloak base image..."
            docker rmi quay.io/keycloak/keycloak:26.2.4 2>/dev/null || print_warning "Could not remove Keycloak base image"
        fi
        
        # Remove Vault image
        if docker images | grep -q "hashicorp/vault"; then
            print_info "Removing Vault image..."
            docker rmi hashicorp/vault 2>/dev/null || print_warning "Could not remove Vault image"
        fi
        
        print_info "Image cleanup completed"
    else
        print_info "Skipping image cleanup"
    fi
}

# Function to cleanup Docker volumes and networks
cleanup_docker_resources() {
    echo ""
    read -p "Do you want to cleanup unused Docker volumes and networks? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning up unused Docker resources..."
        
        # Remove unused volumes
        docker volume prune -f 2>/dev/null || print_warning "Could not prune volumes"
        
        # Remove unused networks
        docker network prune -f 2>/dev/null || print_warning "Could not prune networks"
        
        print_info "Docker resource cleanup completed"
    else
        print_info "Skipping Docker resource cleanup"
    fi
}

# Function to verify removal
verify_removal() {
    echo ""
    print_info "REMOVAL VERIFICATION:"
    echo "====================="
    
    # Check if containers are removed
    if ! container_exists "my-keycloak" && ! container_exists "dev-vault"; then
        print_info "✓ All containers removed successfully"
    else
        if container_exists "my-keycloak"; then
            print_error "✗ Keycloak container still exists"
        fi
        if container_exists "dev-vault"; then
            print_error "✗ Vault container still exists"
        fi
    fi
    
    # Check if ports are free
    if ! netstat -tuln | grep -q ":8080 "; then
        print_info "✓ Port 8080 is now free"
    else
        print_warning "Port 8080 is still in use"
    fi
    
    if ! netstat -tuln | grep -q ":8200 "; then
        print_info "✓ Port 8200 is now free"
    else
        print_warning "Port 8200 is still in use"
    fi
}

# Function to show help
show_help() {
    echo "Vault + Keycloak Uninstallation Script"
    echo "======================================"
    echo ""
    echo "This script will remove:"
    echo "- Keycloak container (my-keycloak)"
    echo "- Vault container (dev-vault)"
    echo "- Optionally: Docker images and unused resources"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --force    Force removal without prompts"
    echo "  -s, --status   Show current container status only"
    echo ""
}

# Main uninstallation flow
main() {
    local force_mode=false
    local status_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force_mode=true
                shift
                ;;
            -s|--status)
                status_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "Vault + Keycloak Integration Uninstallation Script"
    echo "=================================================="
    echo ""
    
    # Show current status
    show_container_status
    
    # If status only mode, exit here
    if [ "$status_only" = true ]; then
        exit 0
    fi
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not available"
        exit 1
    fi
    
    # Check if any containers exist
    if ! container_exists "my-keycloak" && ! container_exists "dev-vault"; then
        print_info "No Vault or Keycloak containers found to remove"
        exit 0
    fi
    
    # Confirm removal unless force mode
    if [ "$force_mode" = false ]; then
        echo ""
        read -p "Are you sure you want to remove Vault and Keycloak containers? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Uninstallation cancelled"
            exit 0
        fi
    fi
    
    echo ""
    print_info "Starting uninstallation process..."
    
    # Remove containers
    remove_keycloak
    remove_vault
    
    # Verify removal
    verify_removal
    
    # Optional cleanup
    if [ "$force_mode" = false ]; then
        cleanup_images
        cleanup_docker_resources
    fi
    
    echo ""
    print_info "Uninstallation completed successfully!"
    
    # Show final status
    show_container_status
}

# Run main function with all arguments
main "$@"
