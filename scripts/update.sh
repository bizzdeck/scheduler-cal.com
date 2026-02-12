#!/bin/bash

# Cal.com Update Script for PM2
# This script updates the application without full rebuild

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_DIR="${APP_DIR:-$(pwd)}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

main() {
    log_info "Updating Cal.com..."
    
    cd "${APP_DIR}"
    
    # Pull latest changes
    log_info "Pulling latest changes..."
    git pull || log_warn "Git pull failed or not a git repository"
    
    # Install dependencies
    log_info "Installing dependencies..."
    yarn install --frozen-lockfile
    
    # Generate Prisma client
    log_info "Generating Prisma client..."
    yarn workspace @calcom/prisma prisma generate
    
    # Run migrations
    if [ -n "${DATABASE_URL}" ] || grep -q "DATABASE_URL" "${APP_DIR}/.env"; then
        log_info "Running database migrations..."
        yarn workspace @calcom/prisma db-deploy || log_warn "Database migration failed"
    fi
    
    # Rebuild applications
    log_info "Rebuilding applications..."
    yarn workspace @calcom/platform-constants build || true
    yarn workspace @calcom/platform-enums build || true
    yarn workspace @calcom/platform-utils build || true
    yarn workspace @calcom/platform-types build || true
    yarn workspace @calcom/platform-libraries build || true
    yarn workspace @calcom/trpc build:server || true
    yarn workspace @calcom/api-v2 build
    yarn workspace @calcom/web build
    
    # Restart PM2 processes
    log_info "Restarting PM2 processes..."
    pm2 restart ecosystem.config.js
    
    log_info "Update completed!"
    log_info "Check status: pm2 status"
}

main "$@"
