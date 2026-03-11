#!/bin/bash
# bootstrap-webserver.sh
# Installs and configures Apache web server on Amazon Linux 2
set -euo pipefail
LOG="/var/log/bootstrap.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Bootstrap started: $(date -u) ==="

yum update -y
yum install -y httpd

# Create a simple web page to verify the server is running
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
  <head><title>XYZ Corp Web Server</title></head>
  <body>
    <h1>XYZ Corp — Web Server Running</h1>
    <p>Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
  </body>
</html>
EOF

systemctl enable httpd
systemctl start httpd

echo "=== Web server bootstrap complete: $(date -u) ==="
