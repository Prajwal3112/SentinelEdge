#!/bin/bash

# Jumpserver Uninstallation Script
# Author: Auto-generated script for Docker-based cleanup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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

# Function to show current status
show_status() {
    print_step "Current Jumpserver Status"
    echo "=========================="
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local found_containers=()
    local running_containers=()
    
    for service in "${services[@]}"; do
        if container_exists "$service"; then
            found_containers+=("$service")
            if container_running "$service"; then
                running_containers+=("$service")
            fi
        fi
    done
    
    if [ ${#found_containers[@]} -eq 0 ]; then
        print_info "No Jumpserver containers found"
        return 1
    fi
    
    echo ""
    echo "Found containers: ${found_containers[*]}"
    echo "Running containers: ${running_containers[*]}"
    
    echo ""
    echo "Container Details:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(jms_|NAMES)" || true
    echo ""
    
    return 0
}

# Function to stop services
stop_services() {
    print_step "Stopping Jumpserver services..."
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local stopped_services=()
    
    for service in "${services[@]}"; do
        if container_running "$service"; then
            print_info "Stopping $service..."
            if docker stop "$service" > /dev/null 2>&1; then
                stopped_services+=("$service")
            else
                print_warning "Failed to stop $service"
            fi
        fi
    done
    
    if [ ${#stopped_services[@]} -gt 0 ]; then
        print_info "✓ Stopped services: ${stopped_services[*]}"
    else
        print_info "No running services to stop"
    fi
}

# Function to remove containers
remove_containers() {
    print_step "Removing Jumpserver containers..."
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local removed_containers=()
    
    for service in "${services[@]}"; do
        if container_exists "$service"; then
            print_info "Removing $service..."
            if docker rm "$service" > /dev/null 2>&1; then
                removed_containers+=("$service")
            else
                print_warning "Failed to remove $service"
            fi
        fi
    done
    
    if [ ${#removed_containers[@]} -gt 0 ]; then
        print_info "✓ Removed containers: ${removed_containers[*]}"
    else
        print_info "No containers to remove"
    fi
}

# Function to remove docker images
remove_images() {
    print_step "Removing Jumpserver Docker images..."
    
    # Get list of Jumpserver related images
    local images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(jumpserver|jms)" 2>/dev/null || true)
    
    if [ -n "$images" ]; then
        print_info "Found Jumpserver images:"
        echo "$images"
        echo ""
        
        echo -n "Do you want to remove these images? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "$images" | while read -r image; do
                if [ -n "$image" ]; then
                    print_info "Removing $image..."
                    docker rmi "$image" 2>/dev/null || print_warning "Failed to remove $image"
                fi
            done
            print_info "✓ Image removal completed"
        else
            print_info "Skipping image removal"
        fi
    else
        print_info "No Jumpserver images found"
    fi
}

# Function to remove volumes
remove_volumes() {
    print_step "Checking for Jumpserver volumes..."
    
    # Get list of volumes that might be related to Jumpserver
    local volumes=$(docker volume ls --format "{{.Name}}" | grep -E "(jms|jumpserver)" 2>/dev/null || true)
    
    if [ -n "$volumes" ]; then
        print_warning "Found potential Jumpserver volumes:"
        echo "$volumes"
        echo ""
        
        echo -n "Do you want to remove these volumes? This will delete all data! (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "$volumes" | while read -r volume; do
                if [ -n "$volume" ]; then
                    print_info "Removing volume $volume..."
                    docker volume rm "$volume" 2>/dev/null || print_warning "Failed to remove $volume"
                fi
            done
            print_info "✓ Volume removal completed"
        else
            print_info "Skipping volume removal"
        fi
    else
        print_info "No Jumpserver volumes found"
    fi
}

# Function to remove installation directory
remove_directory() {
    print_step "Removing installation directory..."
    
    if [ -d "/opt/jumpserver" ]; then
        print_warning "Found Jumpserver installation directory at /opt/jumpserver"
        echo -n "Do you want to remove it? (y/N): "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if sudo rm -rf /opt/jumpserver; then
                print_info "✓ Installation directory removed"
            else
                print_error "Failed to remove installation directory"
            fi
        else
            print_info "Keeping installation directory"
        fi
    else
        print_info "No installation directory found"
    fi
}

# Function to cleanup logs
cleanup_logs() {
    print_step "Cleaning up log files..."
    
    local log_files=("/opt/CyberSentinel_install.log")
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            print_info "Removing $log_file..."
            sudo rm -f "$log_file" || print_warning "Failed to remove $log_file"
        fi
    done
    
    print_info "✓ Log cleanup completed"
}

# Function to cleanup docker system
cleanup_docker_system() {
    echo ""
    echo -n "Do you want to run Docker system cleanup (remove unused containers, networks, images)? (y/N): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_step "Running Docker system cleanup..."
        
        print_info "Pruning unused containers..."
        docker container prune -f 2>/dev/null || print_warning "Failed to prune containers"
        
        print_info "Pruning unused networks..."
        docker network prune -f 2>/dev/null || print_warning "Failed to prune networks"
        
        print_info "Pruning unused volumes..."
        docker volume prune -f 2>/dev/null || print_warning "Failed to prune volumes"
        
        print_info "✓ Docker system cleanup completed"
    else
        print_info "Skipping Docker system cleanup"
    fi
}

# Function to verify removal
verify_removal() {
    print_step "Verifying removal..."
    
    local services=("jms_core" "jms_lion" "jms_web" "jms_chen" "jms_koko" "jms_celery" "jms_redis")
    local remaining_containers=()
    
    for service in "${services[@]}"; do
        if container_exists "$service"; then
            remaining_containers+=("$service")
        fi
    done
    
    if [ ${#remaining_containers[@]} -eq 0 ]; then
        print_info "✓ All Jumpserver containers removed successfully"
    else
        print_warning "Some containers still exist: ${remaining_containers[*]}"
    fi
    
    # Check if ports are free
    local ports=(80 443 2222)
    for port in "${ports[@]}"; do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port " && ! ss -tuln 2>/dev/null | grep -q ":$port "; then
            print_info "✓ Port $port is now free"
        else
            print_warning "Port $port is still in use"
        fi
    done
    
    # Check installation directory
    if [ ! -d "/opt/jumpserver" ]; then
        print_info "✓ Installation directory removed"
    else
        print_warning "Installation directory still exists"
    fi
}

# Function to show help
show_help() {
    echo "Jumpserver Uninstallation Script"
    echo "================================"
    echo ""
    echo "This script will remove:"
    echo "• All Jumpserver containers (jms_*)"
    echo "• Jumpserver Docker images (optional)"
    echo "• Jumpserver volumes and data (optional)"
    echo "• Installation directory /opt/jumpserver (optional)"
    echo "• Log files"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -f, --force     Force removal without interactive prompts"
    echo "  -s, --status    Show current status only"
    echo "  --keep-data     Keep volumes and data directories"
    echo "  --keep-images   Keep Docker images"
    echo ""
}

# Main uninstallation flow
main() {
    local force_mode=false
    local status_only=false
    local keep_data=false
    local keep_images=false
    
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
            --keep-data)
                keep_data=true
                shift
                ;;
            --keep-images)
                keep_images=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo ""
    echo "============================================"
    echo "    Jumpserver Uninstallation Script"
    echo "============================================"
    echo ""
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not available"
        exit 1
    fi
    
    # Show current status
    if ! show_status; then
        if [ "$status_only" = true ]; then
            exit 0
        fi
        print_info "No Jumpserver installation found"
        exit 0
    fi
    
    # If status only mode, exit here
    if [ "$status_only" = true ]; then
        exit 0
    fi
    
    # Confirm removal unless force mode
    if [ "$force_mode" = false ]; then
        echo ""
        echo -n "Are you sure you want to completely remove Jumpserver? (y/N): "
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Uninstallation cancelled"
            exit 0
        fi
    fi
    
    echo ""
    print_info "Starting Jumpserver removal process..."
    
    # Stop services
    stop_services
    
    # Remove containers
    remove_containers
    
    # Remove images (if not keeping)
    if [ "$keep_images" = false ] && [ "$force_mode" = false ]; then
        remove_images
    fi
    
    # Remove volumes (if not keeping data)
    if [ "$keep_data" = false ] && [ "$force_mode" = false ]; then
        remove_volumes
    fi
    
    # Remove installation directory
    if [ "$force_mode" = false ]; then
        remove_directory
    fi
    
    # Cleanup logs
    cleanup_logs
    
    # Docker system cleanup
    if [ "$force_mode" = false ]; then
        cleanup_docker_system
    fi
    
    # Verify removal
    verify_removal
    
    echo ""
    echo "============================================"
    print_info "JUMPSERVER UNINSTALLATION COMPLETED!"
    echo "============================================"
    
    # Show final status
    echo ""
    show_status > /dev/null 2>&1 || print_info "No Jumpserver components remaining"
}

# Error handling
trap 'print_error "Uninstallation failed at line $LINENO"' ERR

# Run main function with all arguments
main "$@"
