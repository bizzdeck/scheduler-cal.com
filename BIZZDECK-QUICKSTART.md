# BizzDeck Cal.com Quick Start & Deployment Guide

This guide combines quick start instructions with comprehensive deployment steps for BizzDeck's Cal.com scheduler using PM2 process manager.

## 🚀 Quick Deployment (5 minutes)

### Prerequisites

- Ubuntu/Debian Linux VM (or similar)
- Node.js 20.x or higher
- Yarn 4.12.0 or higher
- PostgreSQL database
- PM2 installed globally
- Git (for CI/CD)

### On Your VM:

```bash
# 1. Install Node.js and Yarn
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo corepack enable
sudo corepack prepare yarn@4.12.0 --activate

# 2. Install PM2
sudo npm install -g pm2

# 3. Install PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

# Create database
sudo -u postgres psql
CREATE DATABASE calendso;
CREATE USER calcom_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE calendso TO calcom_user;
\q

# 4. Clone and setup
cd /opt
git clone <your-repo-url> calcom
cd calcom

# 5. Configure environment
cp .env.example .env
nano .env  # Edit with your settings

# 6. Deploy
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Verify:

```bash
pm2 status
pm2 logs
```

## 🔧 Environment Configuration

### Minimum Required Variables

```env
DATABASE_URL="postgresql://calcom_user:your_password@localhost:5432/calendso"
DATABASE_DIRECT_URL="postgresql://calcom_user:your_password@localhost:5432/calendso"
NEXT_PUBLIC_WEBAPP_URL="https://yourdomain.com"
NEXTAUTH_URL="https://yourdomain.com"
NEXTAUTH_SECRET="$(openssl rand -base64 32)"
CALENDSO_ENCRYPTION_KEY="$(openssl rand -base64 24)"
```

### Complete Environment Setup

```env
# Database
DATABASE_URL="postgresql://calcom_user:your_password@localhost:5432/calendso"
DATABASE_DIRECT_URL="postgresql://calcom_user:your_password@localhost:5432/calendso"

# Application URLs
NEXT_PUBLIC_WEBAPP_URL="https://yourdomain.com"
NEXT_PUBLIC_WEBSITE_URL="https://yourdomain.com"
NEXT_PUBLIC_EMBED_LIB_URL="https://yourdomain.com/embed/embed.js"

# API v2 URL (if deploying API v2 separately)
NEXT_PUBLIC_API_V2_URL="https://api.yourdomain.com/api/v2"

# Authentication
NEXTAUTH_URL="https://yourdomain.com"
NEXTAUTH_SECRET="generate-with-openssl-rand-base64-32"
CALENDSO_ENCRYPTION_KEY="generate-with-openssl-rand-base64-24"

# Email (optional but recommended)
EMAIL_FROM="noreply@yourdomain.com"
EMAIL_SERVER_HOST="smtp.example.com"
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER="your-email@example.com"
EMAIL_SERVER_PASSWORD="your-password"
```

Generate secrets:

```bash
openssl rand -base64 32  # For NEXTAUTH_SECRET
openssl rand -base64 24  # For CALENDSO_ENCRYPTION_KEY
```

## 📋 Common PM2 Commands

```bash
# Start
pm2 start ecosystem.config.js

# Stop
pm2 stop ecosystem.config.js

# Restart
pm2 restart ecosystem.config.js

# View logs
pm2 logs
pm2 logs calcom-web
pm2 logs calcom-api-v2

# Monitor
pm2 monit

# Save PM2 process list
pm2 save

# Setup PM2 to start on system boot
pm2 startup
pm2 save

# Update application
./scripts/update.sh
```

## 🔄 CI/CD Setup

### GitHub Actions Secrets

Add these secrets to your GitHub repository:

1. Go to Settings → Secrets and variables → Actions
2. Add the following secrets:

- `VM_HOST`: Your VM IP address or hostname
- `VM_USER`: SSH username (e.g., `ubuntu`, `deploy`)
- `VM_SSH_KEY`: Private SSH key for authentication
- `VM_PORT`: SSH port (default: 22)
- `SLACK_WEBHOOK_URL`: (Optional) Slack webhook for notifications

### SSH Key Setup

1. **Generate SSH key pair (if not exists):**

```bash
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions
```

2. **Copy public key to VM:**

```bash
ssh-copy-id -i ~/.ssh/github_actions.pub user@your-vm-ip
```

3. **Add private key to GitHub Secrets:**

```bash
cat ~/.ssh/github_actions
# Copy the output and add as VM_SSH_KEY secret
```

### Workflow

The CI/CD workflow (`.github/workflows/deploy-pm2.yml`) will:

1. Build applications
2. Create deployment package
3. Copy to VM via SCP
4. Execute deployment script
5. Verify deployment

**Trigger deployment:**

- Push to `main` or `master` branch (automatic)
- Manual trigger via GitHub Actions UI

## 🌐 Reverse Proxy Setup

### Nginx Configuration

Create `/etc/nginx/sites-available/calcom`:

```nginx
# Web App
server {
    listen 80;
    server_name yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# API v2 (if exposed separately)
server {
    listen 80;
    server_name api.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:5555;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and restart:

```bash
sudo ln -s /etc/nginx/sites-available/calcom /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### SSL with Let's Encrypt

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d api.yourdomain.com
```

## 📊 Monitoring

### PM2 Monitoring

```bash
# Real-time monitoring
pm2 monit

# View metrics
pm2 describe calcom-web
pm2 describe calcom-api-v2
```

### Log Management

Logs are stored in `./logs/` directory:

- `web-error.log` - Web app errors
- `web-out.log` - Web app output
- `api-v2-error.log` - API v2 errors
- `api-v2-out.log` - API v2 output

Rotate logs:

```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

### Health Checks

```bash
# Check web app
curl http://localhost:3000/api/health

# Check API v2
curl http://localhost:5555/health
```

## 🔧 Troubleshooting

### Applications won't start

1. Check logs:
```bash
pm2 logs --err
```

2. Check environment variables:
```bash
pm2 env 0  # For web app
pm2 env 1  # For API v2
```

3. Verify database connection:
```bash
yarn workspace @calcom/prisma prisma db pull
```

### Build failures

1. Clear build cache:
```bash
yarn clean
rm -rf node_modules
yarn install
```

2. Check Node.js version:
```bash
node --version  # Should be 20.x
```

### Database migration issues

```bash
# Check migration status
yarn workspace @calcom/prisma prisma migrate status

# Reset database (WARNING: deletes all data)
yarn workspace @calcom/prisma prisma migrate reset
```

## 💾 Backup

### Database Backup

```bash
# Create backup script
cat > /opt/backup-calcom.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/calcom-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump -U calcom_user calendso > "$BACKUP_DIR/db_$TIMESTAMP.sql"
find "$BACKUP_DIR" -name "db_*.sql" -mtime +7 -delete
EOF

chmod +x /opt/backup-calcom.sh

# Add to crontab (daily at 2 AM)
crontab -e
0 2 * * * /opt/backup-calcom.sh
```

### Application Backup

```bash
# Backup application directory
tar -czf calcom-backup-$(date +%Y%m%d).tar.gz /opt/calcom --exclude='node_modules' --exclude='.next' --exclude='.turbo'
```

## 🔒 Security

1. **Firewall:**
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

2. **Keep system updated:**
```bash
sudo apt-get update && sudo apt-get upgrade -y
```

3. **Use strong passwords** for database and environment variables

4. **Regular backups** of database and application

## 📚 Support

For issues and questions:
- Check logs: `pm2 logs`
- Review Cal.com documentation: https://cal.com/docs
- GitHub Issues: https://github.com/calcom/cal.com/issues

---

**Note:** This guide combines the quick start and comprehensive deployment documentation for BizzDeck's Cal.com scheduler. For the most up-to-date information, refer to the individual QUICK_START.md and DEPLOYMENT.md files.
