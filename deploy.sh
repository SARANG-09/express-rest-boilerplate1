#!/bin/bash

# Update and install basic packages
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y curl gnupg git

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Clone the Node.js repository
git clone https://github.com/danielfsousa/express-rest-boilerplate.git
cd express-rest-boilerplate
npm install
# Set up environment file
cp .env.example .env

# Install MongoDB 7.0
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# Install Redis
sudo apt install -y redis-server
sudo systemctl enable redis-server.service

# Install NGINX
sudo apt install -y nginx

# Configure NGINX for Node.js
sudo bash -c 'cat <<EOF > /etc/nginx/sites-available/nodeapp
server {
    listen 80;
    server_name your_domain_or_IP;  # Replace this with your domain or IP

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF'

# Remove the existing symbolic link if it exists
if [ -L /etc/nginx/sites-enabled/nodeapp ]; then
    sudo rm /etc/nginx/sites-enabled/nodeapp
fi

# Enable the NGINX site configuration
sudo ln -s /etc/nginx/sites-available/nodeapp /etc/nginx/sites-enabled/

# Test NGINX configuration for syntax errors
if ! sudo nginx -t; then
    echo "NGINX configuration test failed. Please check your configuration."
    exit 1  # Exit the script with an error code
fi

# Restart NGINX and check status
sudo systemctl restart nginx

# Check NGINX status
if ! sudo systemctl status nginx.service; then
    echo "NGINX failed to start. Check the logs for details:"
    journalctl -xeu nginx.service
    exit 1  # Exit the script with an error code
fi
# Start Node.js application
sudo npm install -g pm2
pm2 start src/index.js --name nodeapp
pm2 startup
pm2 update &
pm2 save

node -v
cd /root/express-rest-boilerplate
rm -rf node_modules yarn.lock
yarn install
yarn install --pure-lockfile

# Build the Docker image and push it to Docker Hub
docker build -t sarang8833/express-rest-es2017-boilerplate .
docker push sarang8833/express-rest-es2017-boilerplate:latest
# Ensure DEPLOY_SERVER is set correctly

# SSH into the deployment server and run commands
ssh -i /root/tokyo.pem ubuntu@54.178.125.224
docker pull sarang8833/express-rest-es2017-boilerplate
docker stop api-boilerplate || true
docker rm api-boilerplate || true
docker rmi sarang8833/express-rest-es2017-boilerplate:current || true
docker tag sarang8833/express-rest-es2017-boilerplate:latest sarang8833/express-rest-es2017-boilerplate:current
docker run -d --restart always --name api-boilerplate -p 3000:3000 sarang8833/express-rest-es2017-boilerplate:current
EOF
