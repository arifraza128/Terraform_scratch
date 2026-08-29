#!/bin/bash
set -euxo pipefail

# Update and install unzip
yum update -y
yum install -y unzip

# Install Node.js & npm (compatible with both Amazon Linux 2 and 2023)
if command -v dnf &> /dev/null; then
  dnf install -y nodejs npm
else
  curl -sL https://rpm.nodesource.com/setup_22.x | bash -
  yum install -y nodejs
fi

# Create app directory
mkdir -p /opt/web

# Decode the zip file and extract it
echo "${app_zip_base64}" | base64 -d > /opt/app.zip
unzip -o /opt/app.zip -d /opt/web

# Build frontend source code on the VM
cd /opt/web/frontend
npm install
npm run build

# Copy built assets to backend public hosting folder
mkdir -p /opt/web/backend/public
cp -r /opt/web/frontend/dist/* /opt/web/backend/public/

# Install production dependencies for Express backend
cd /opt/web/backend
npm install --only=production

# Set up Node.js Systemd Service
cat > /etc/systemd/system/nodeapp.service <<'EOF'
[Unit]
Description=NodeJS Express Web App
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/web/backend
Environment=PORT=${app_port}
ExecStart=/usr/bin/node /opt/web/backend/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nodeapp
systemctl restart nodeapp
