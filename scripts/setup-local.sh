#!/bin/bash
# Local development setup script

echo "==================================="
echo "Ultrastore Local Development Setup"
echo "==================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cat > .env << EOF
# Database Configuration
MYSQL_ROOT_PASSWORD=dev_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=dev_wordpress_password

# WordPress Configuration
WORDPRESS_DB_HOST=mysql:3306
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=dev_wordpress_password
WORDPRESS_DB_NAME=wordpress
WORDPRESS_TABLE_PREFIX=wp_
WORDPRESS_DEBUG=1

# WordPress Site Configuration
WORDPRESS_URL=http://localhost:8080
WORDPRESS_TITLE=Ultrastore Development
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=admin
WORDPRESS_ADMIN_EMAIL=admin@localhost.com

# Production Server Configuration (for deployment)
PRODUCTION_HOST=shop.ultrastore.khizrim.online
PRODUCTION_USER=root
PRODUCTION_PORT=22
PRODUCTION_THEME_PATH=/var/www/html/wp-content/themes/

# WooCommerce Test Keys (optional)
WC_CONSUMER_KEY=
WC_CONSUMER_SECRET=
EOF
    echo "✓ .env file created"
else
    echo "✓ .env file already exists"
fi

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p plugins uploads
touch plugins/.gitkeep

# Make scripts executable
chmod +x scripts/*.sh

# Start Docker containers
echo "Starting Docker containers..."
docker-compose up -d

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
sleep 20

# Initialize WordPress
echo "Initializing WordPress..."
docker-compose exec wordpress bash /scripts/init-wordpress.sh

echo ""
echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo "Access your site at: http://localhost:8080"
echo "Admin panel: http://localhost:8080/wp-admin"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "To stop the containers: docker-compose down"
echo "To view logs: docker-compose logs -f"
echo "==================================="
