#!/bin/bash
set -euxo pipefail

# Application Version: ${app_version}

# Redirect all script execution output to the log file to debug startup if needed
exec > >(tee -a /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting user-data execution ==="

# 1. Update apt package index
apt-get update -y

# 2. Install essential packages: unzip, curl, and awscli
apt-get install -y unzip curl awscli

# 3. Install Node.js 20 LTS from NodeSource
echo "=== Installing Node.js ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify installation
node -v
npm -v

# 4. Create application directory
mkdir -p /opt/web

# 5. Download app.zip from the private S3 bucket
echo "=== Downloading application from S3 ==="
aws s3 cp s3://${s3_bucket_name}/app.zip /opt/app.zip

# 6. Extract the archive
echo "=== Extracting application ==="
unzip -o /opt/app.zip -d /opt/web

# 7. Install frontend dependencies and build assets
echo "=== Building frontend ==="
cd /opt/web/frontend
npm install
npm run build

# Copy built assets to backend's public hosting directory
mkdir -p /opt/web/backend/public
cp -r /opt/web/frontend/dist/* /opt/web/backend/public/

# 8. Install production dependencies for Express backend
echo "=== Preparing backend ==="
cd /opt/web/backend
npm install --only=production

# 9. Setup logs and permissions for ubuntu user
touch /home/ubuntu/app.log
chown ubuntu:ubuntu /home/ubuntu/app.log
chmod 666 /home/ubuntu/app.log

# 10. Configure and start Node.js Systemd Service
echo "=== Setting up Systemd service ==="
cat > /etc/systemd/system/nodeapp.service <<EOF
[Unit]
Description=NodeJS Express Web App
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/web/backend
Environment=PORT=${app_port}
ExecStart=/bin/sh -c 'exec /usr/bin/node /opt/web/backend/server.js >> /home/ubuntu/app.log 2>&1'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start service
systemctl daemon-reload
systemctl enable nodeapp
systemctl restart nodeapp

echo "=== Startup script finished ==="
