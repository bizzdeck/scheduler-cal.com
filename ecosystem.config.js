/**
 * PM2 Ecosystem Configuration for Cal.com
 * 
 * This file configures PM2 to manage:
 * - Web app (Next.js)
 * - API v2 server (NestJS)
 * 
 * Usage:
 *   pm2 start ecosystem.config.js
 *   pm2 stop ecosystem.config.js
 *   pm2 restart ecosystem.config.js
 *   pm2 delete ecosystem.config.js
 */

module.exports = {
  apps: [
    {
      name: 'calcom-web',
      script: 'yarn',
      args: 'workspace @calcom/web start',
      cwd: './',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      error_file: './logs/web-error.log',
      out_file: './logs/web-out.log',
      log_file: './logs/web-combined.log',
      time: true,
      merge_logs: true,
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
    },
    {
      name: 'calcom-api-v2',
      script: 'yarn',
      args: 'workspace @calcom/api-v2 start:prod',
      cwd: './',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 5555,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 5555,
      },
      error_file: './logs/api-v2-error.log',
      out_file: './logs/api-v2-out.log',
      log_file: './logs/api-v2-combined.log',
      time: true,
      merge_logs: true,
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
    },
  ],
};
