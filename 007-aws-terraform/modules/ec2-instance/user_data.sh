#!/bin/bash
set -euo pipefail

# Update system packages
dnf update -y

# Install Nginx web server
dnf install -y nginx

# Configure custom application port if different from standard port 80
if [ "${app_port}" != "80" ]; then
  sed -i -E "s/listen\s+80;/listen ${app_port};/g" /etc/nginx/nginx.conf
  sed -i -E "s/listen\s+\[::\]:80;/listen [::]:${app_port};/g" /etc/nginx/nginx.conf
fi

# Deploy parameterized landing page
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>${server_name}</title>
</head>
<body>
  <h1>${server_name}</h1>
  <p>Environment: <strong>${environment}</strong></p>
  <p>Application Port: <strong>${app_port}</strong></p>
  <p>Provisioned by Terraform</p>
</body>
</html>
EOF

# Enable and start Nginx service
systemctl start nginx
systemctl enable nginx
