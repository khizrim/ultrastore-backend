#!/bin/bash
# WordPress initialization script for local development

echo "Waiting for WordPress to be ready..."
sleep 10

# Check if WordPress is already installed
if wp core is-installed --allow-root 2>/dev/null; then
    echo "WordPress is already installed."
else
    echo "Installing WordPress..."
    wp core install \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Set permalink structure for REST API
    wp rewrite structure '/%postname%/' --allow-root
    wp rewrite flush --allow-root

    # Install and activate WooCommerce
    echo "Installing WooCommerce..."
    wp plugin install woocommerce --activate --allow-root

    # Install other useful plugins for development
    echo "Installing development plugins..."
    wp plugin install query-monitor --activate --allow-root
    wp plugin install wp-mail-smtp --allow-root
    
    # Install JWT Authentication for WP REST API (for headless auth)
    wp plugin install jwt-authentication-for-wp-rest-api --activate --allow-root

    # Set WooCommerce settings for development
    wp option update woocommerce_store_address "123 Main St" --allow-root
    wp option update woocommerce_store_city "Test City" --allow-root
    wp option update woocommerce_default_country "US:CA" --allow-root
    wp option update woocommerce_currency "USD" --allow-root
    wp option update woocommerce_api_enabled "yes" --allow-root

    # Create sample products
    echo "Creating sample WooCommerce products..."
    wp wc product create --name="Sample Product 1" --type=simple --regular_price=19.99 --user=1 --allow-root
    wp wc product create --name="Sample Product 2" --type=simple --regular_price=29.99 --user=1 --allow-root
    wp wc product create --name="Sample Product 3" --type=simple --regular_price=39.99 --user=1 --allow-root

    echo "WordPress installation complete!"
fi

# Always activate our theme
echo "Activating Ultrastore Headless theme..."
wp theme activate ultrastore-headless --allow-root

# Display API endpoints
echo ""
echo "==================================="
echo "WordPress is ready!"
echo "==================================="
echo "Admin URL: ${WORDPRESS_URL}/wp-admin"
echo "Username: ${WORDPRESS_ADMIN_USER}"
echo "Password: ${WORDPRESS_ADMIN_PASSWORD}"
echo ""
echo "REST API: ${WORDPRESS_URL}/wp-json/"
echo "WooCommerce API: ${WORDPRESS_URL}/wp-json/wc/v3/"
echo "==================================="
