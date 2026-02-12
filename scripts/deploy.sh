#!/bin/bash

# Cal.com Deployment Script for PM2
# This script handles building and deploying Cal.com applications

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="${APP_DIR:-$(pwd)}"
LOG_DIR="${APP_DIR}/logs"
NODE_ENV="${NODE_ENV:-production}"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    log_warn "Running as root. Consider using a non-root user for production."
fi

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v yarn &> /dev/null; then
        log_error "Yarn is not installed"
        exit 1
    fi
    
    if ! command -v pm2 &> /dev/null; then
        log_error "PM2 is not installed. Install it with: npm install -g pm2"
        exit 1
    fi
    
    if [ ! -f "${APP_DIR}/.env" ]; then
        log_warn ".env file not found. Copying from .env.example..."
        if [ -f "${APP_DIR}/.env.example" ]; then
            cp "${APP_DIR}/.env.example" "${APP_DIR}/.env"
            log_warn "Please update .env file with your configuration before continuing"
        else
            log_error ".env.example not found"
            exit 1
        fi
    fi
    
    log_info "Prerequisites check passed"
}

# Create necessary directories
setup_directories() {
    log_info "Setting up directories..."
    mkdir -p "${LOG_DIR}"
    log_info "Directories created"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    cd "${APP_DIR}"
    yarn install --frozen-lockfile
    log_info "Dependencies installed"
}

# Generate Prisma client
setup_prisma() {
    log_info "Setting up Prisma..."
    cd "${APP_DIR}"
    yarn workspace @calcom/prisma prisma generate
    
    # Run migrations if DATABASE_URL is set
    if [ -n "${DATABASE_URL}" ] || grep -q "DATABASE_URL" "${APP_DIR}/.env"; then
        log_info "Running database migrations..."
        yarn workspace @calcom/prisma db-deploy || log_warn "Database migration failed or database not accessible"
    else
        log_warn "DATABASE_URL not set. Skipping database migrations."
    fi
}

# Build applications
build_applications() {
    log_info "Building applications..."
    cd "${APP_DIR}"
    
    # Build platform dependencies first
    log_info "Building platform dependencies..."
    yarn workspace @calcom/platform-constants build || true
    yarn workspace @calcom/platform-enums build || true
    yarn workspace @calcom/platform-utils build || true
    yarn workspace @calcom/platform-types build || true
    yarn workspace @calcom/platform-libraries build || true
    
    # Build tRPC server
    log_info "Building tRPC server..."
    yarn workspace @calcom/trpc build:server || true
    
    # Build API v2
    log_info "Building API v2..."
    yarn workspace @calcom/api-v2 build || log_error "API v2 build failed"
    
    # Build web app
    log_info "Building web app..."
    yarn workspace @calcom/web build || log_error "Web app build failed"
    
    log_info "Build completed"
}

# Deploy with PM2
deploy_pm2() {
    log_info "Deploying with PM2..."
    cd "${APP_DIR}"
    
    # Stop existing processes if running
    pm2 stop ecosystem.config.js --silent || true
    pm2 delete ecosystem.config.js --silent || true
    
    # Start applications
    pm2 start ecosystem.config.js
    
    # Save PM2 process list
    pm2 save
    
    # Setup PM2 startup script
    log_info "Setting up PM2 startup script..."
    pm2 startup || log_warn "PM2 startup script setup failed. You may need to run it manually."
    
    log_info "Deployment completed"
    log_info "View logs with: pm2 logs"
    log_info "Monitor with: pm2 monit"
    log_info "Status: pm2 status"
}

# Main deployment flow
main() {
    log_info "Starting Cal.com deployment..."
    log_info "Working directory: ${APP_DIR}"
    log_info "Environment: ${NODE_ENV}"
    
    check_prerequisites
    setup_directories
    install_dependencies
    setup_prisma
    build_applications
    deploy_pm2
    
    log_info "Deployment completed successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Verify applications are running: pm2 status"
    log_info "  2. Check logs: pm2 logs"
    log_info "  3. Monitor: pm2 monit"
    log_info "  4. Setup reverse proxy (nginx/caddy) to forward requests to ports 3000 (web) and 5555 (api-v2)"
}

# Run main function
main "$@"
