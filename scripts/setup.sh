#!/bin/bash

# =================================
# Ultrastore WordPress First Run Setup
# =================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WP_CLI="docker-compose exec -T wordpress wp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_services() {
    log_info "Checking if services are running..."
    if ! docker-compose ps | grep -q "ultrastore-wordpress.*Up"; then
        log_error "WordPress container is not running. Please run 'docker-compose up -d' first."
        exit 1
    fi
    
    if ! docker-compose ps | grep -q "ultrastore-mysql.*Up"; then
        log_error "Database container is not running. Please run 'docker-compose up -d' first."
        exit 1
    fi
    log_success "Services are running"
}

wait_for_wordpress() {
    log_info "Waiting for WordPress to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check if WP-CLI can connect to WordPress (even if not installed)
        if $WP_CLI core version --allow-root 2>/dev/null >/dev/null; then
            log_success "WordPress is ready"
            return 0
        fi
        
        if [ $attempt -eq 1 ]; then
            log_info "WordPress not ready yet, waiting..."
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "WordPress failed to become ready after $max_attempts attempts"
    return 1
}

install_wordpress() {
    log_info "Installing WordPress..."
    
    # Get configuration from environment or use defaults
    WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
    WP_ADMIN_PASS="${WP_ADMIN_PASS:-admin}"
    WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
    WP_TITLE="${WP_TITLE:-Ultrastore}"
    WP_URL="${WP_URL:-${WP_DOMAIN:-localhost:8080}}"
    WP_DOMAIN="${WP_DOMAIN:-localhost}"
    
    if ! $WP_CLI core is-installed --allow-root 2>/dev/null; then
        $WP_CLI core install \
            --url="$WP_URL" \
            --title="$WP_TITLE" \
            --admin_user="$WP_ADMIN_USER" \
            --admin_password="$WP_ADMIN_PASS" \
            --admin_email="$WP_ADMIN_EMAIL" \
            --allow-root
        log_success "WordPress installed successfully"
    else
        log_success "WordPress is already installed"
    fi
    
    # Install Russian language pack
    log_info "Installing Russian language pack..."
    $WP_CLI language core install ru_RU --activate --allow-root
    log_success "Russian language pack installed and activated"
}

remove_default_themes() {
    log_info "Removing default WordPress themes..."
    
    # Get list of installed themes
    local themes
    themes=$($WP_CLI theme list --format=csv --allow-root | tail -n +2 | cut -d',' -f1)
    
    for theme in $themes; do
        if [[ "$theme" == twenty* ]]; then
            log_info "Removing theme: $theme"
            $WP_CLI theme delete "$theme" --allow-root 2>/dev/null || log_warning "Could not remove theme: $theme"
        fi
    done
    
    log_success "Default themes removed"
}

setup_ultrastore_theme() {
    log_info "Setting up Ultrastore Headless theme..."
    
    # Check if ultrastore-headless theme exists in the themes directory
    if $WP_CLI theme is-installed ultrastore-headless --allow-root 2>/dev/null; then
        log_success "ultrastore-headless theme found in themes directory"
    else
        log_error "ultrastore-headless theme not found. Theme files should be in ./themes/ultrastore-headless/"
        log_error "Please ensure the theme is properly mounted in the container"
        exit 1
    fi
    
    # Activate the theme
    $WP_CLI theme activate ultrastore-headless --allow-root
    log_success "Activated ultrastore-headless theme"
    
    log_success "Theme setup completed"
}

remove_default_plugins() {
    log_info "Removing default WordPress plugins..."
    
    # List of default plugins to remove
    local default_plugins=("akismet" "hello")
    
    for plugin in "${default_plugins[@]}"; do
        if $WP_CLI plugin is-installed "$plugin" --allow-root 2>/dev/null; then
            log_info "Removing plugin: $plugin"
            $WP_CLI plugin deactivate "$plugin" --allow-root 2>/dev/null || true
            $WP_CLI plugin delete "$plugin" --allow-root 2>/dev/null || log_warning "Could not remove plugin: $plugin"
        fi
    done
    
    log_success "Default plugins removed"
}

install_woocommerce() {
    log_info "Installing WooCommerce..."
    
    if ! $WP_CLI plugin is-installed woocommerce --allow-root 2>/dev/null; then
        # Install WooCommerce 8.9.3 which is compatible with WordPress 6.6
        $WP_CLI plugin install woocommerce --version=8.9.3 --activate --allow-root
        log_success "WooCommerce 8.9.3 installed and activated"
    else
        $WP_CLI plugin activate woocommerce --allow-root 2>/dev/null || true
        log_success "WooCommerce is already installed and activated"
    fi
    
    # Install Russian language pack for WooCommerce
    log_info "Installing WooCommerce Russian translations..."
    $WP_CLI language plugin install woocommerce ru_RU --allow-root 2>/dev/null || log_warning "WooCommerce Russian translations may not be available"
    log_success "WooCommerce translations updated"
}

configure_woocommerce() {
    log_info "Configuring WooCommerce with Ultrastore data..."
    
    # Store information
    $WP_CLI option update woocommerce_store_address "Лиговский проспект, 73" --allow-root
    $WP_CLI option update woocommerce_store_address_2 "офис 506, 5 этаж" --allow-root
    $WP_CLI option update woocommerce_store_city "Санкт-Петербург" --allow-root
    $WP_CLI option update woocommerce_default_country "RU:SPE" --allow-root
    $WP_CLI option update woocommerce_store_postcode "191040" --allow-root
    $WP_CLI option update woocommerce_currency "RUB" --allow-root
    
    # Store settings
    $WP_CLI option update woocommerce_product_type "both" --allow-root
    $WP_CLI option update woocommerce_allow_tracking "no" --allow-root
    $WP_CLI option update woocommerce_weight_unit "kg" --allow-root
    $WP_CLI option update woocommerce_dimension_unit "cm" --allow-root
    
    # Pricing settings
    $WP_CLI option update woocommerce_price_thousand_sep " " --allow-root
    $WP_CLI option update woocommerce_price_decimal_sep "," --allow-root
    $WP_CLI option update woocommerce_price_num_decimals "0" --allow-root
    $WP_CLI option update woocommerce_currency_pos "right_space" --allow-root
    
    # Tax settings (Russian VAT)
    $WP_CLI option update woocommerce_calc_taxes "yes" --allow-root
    $WP_CLI option update woocommerce_prices_include_tax "yes" --allow-root
    $WP_CLI option update woocommerce_tax_display_shop "incl" --allow-root
    $WP_CLI option update woocommerce_tax_display_cart "incl" --allow-root
    
    # Enable REST API
    $WP_CLI option update woocommerce_api_enabled "yes" --allow-root
    
    # Set up basic pages
    $WP_CLI wc tool run install_pages --user=1 --allow-root 2>/dev/null || true
    
    # Skip WooCommerce setup wizard
    $WP_CLI option update woocommerce_onboarding_opt_in "no" --allow-root
    $WP_CLI option update woocommerce_setup_wizard_completed "yes" --allow-root
    
    # Create Russian VAT tax rate
    $WP_CLI wc tax create \
        --country="RU" \
        --rate="20" \
        --name="НДС" \
        --class="standard" \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    log_success "WooCommerce configured for Russian market"
}

update_translations() {
    log_info "Updating all translations..."
    
    # Update core translations
    $WP_CLI language core update --allow-root 2>/dev/null || log_warning "Core translations update failed"
    
    # Update plugin translations
    $WP_CLI language plugin update --all --allow-root 2>/dev/null || log_warning "Plugin translations update failed"
    
    # Update theme translations (if any)
    $WP_CLI language theme update --all --allow-root 2>/dev/null || log_warning "Theme translations update failed"
    
    log_success "All translations updated"
}

configure_wordpress_for_headless() {
    log_info "Configuring WordPress for headless use..."
    
    # Enable pretty permalinks
    $WP_CLI rewrite structure '/%postname%/' --allow-root
    $WP_CLI rewrite flush --allow-root
    
    # Get configuration from environment
    WP_DOMAIN="${WP_DOMAIN:-localhost}"
    WP_TITLE="${WP_TITLE:-Ultrastore}"
    STORE_EMAIL="${STORE_EMAIL:-shop@${WP_DOMAIN}}"
    ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
    
    # Ensure Russian is set as the site language
    $WP_CLI option update WPLANG "ru_RU" --allow-root
    
    # Update site settings for Ultrastore
    $WP_CLI option update blogdescription "Магазин техники Apple в Санкт-Петербурге - iPhone, MacBook, iPad" --allow-root
    $WP_CLI option update admin_email "$ADMIN_EMAIL" --allow-root
    $WP_CLI option update date_format "d.m.Y" --allow-root
    $WP_CLI option update time_format "H:i" --allow-root
    $WP_CLI option update start_of_week "1" --allow-root
    
    # Store contact information
    $WP_CLI option update woocommerce_email_from_address "$STORE_EMAIL" --allow-root
    $WP_CLI option update woocommerce_email_from_name "$WP_TITLE" --allow-root
    
    # Disable comments by default
    $WP_CLI option update default_comment_status "closed" --allow-root
    $WP_CLI option update default_ping_status "closed" --allow-root
    
    log_success "WordPress configured for headless use with Russian localization"
}

create_sample_content() {
    log_info "Creating Apple product categories and sample products..."
    
    # Create product categories
    log_info "Creating product categories..."
    
    # Create main Apple categories
    $WP_CLI wc product_cat create \
        --name="iPhone" \
        --description="Смартфоны Apple iPhone" \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    $WP_CLI wc product_cat create \
        --name="MacBook" \
        --description="Ноутбуки Apple MacBook" \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    $WP_CLI wc product_cat create \
        --name="iPad" \
        --description="Планшеты Apple iPad" \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    $WP_CLI wc product_cat create \
        --name="Apple Watch" \
        --description="Умные часы Apple Watch" \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    $WP_CLI wc product_cat create \
        --name="AirPods" \
        --description="Беспроводные наушники Apple AirPods" \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    $WP_CLI wc product_cat create \
        --name="Аксессуары" \
        --description="Аксессуары для устройств Apple" \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    # Create product attributes
    log_info "Creating product attributes..."
    
    $WP_CLI wc product_attribute create \
        --name="Цвет" \
        --slug="color" \
        --type="select" \
        --order_by="menu_order" \
        --has_archives=true \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    $WP_CLI wc product_attribute create \
        --name="Память" \
        --slug="storage" \
        --type="select" \
        --order_by="menu_order" \
        --has_archives=true \
        --user=1 \
        --allow-root 2>/dev/null || true
    
    # Check if products already exist
    local product_count
    product_count=$($WP_CLI post list --post_type=product --format=count --allow-root)
    
    if [ "$product_count" -eq 0 ]; then
        log_info "Creating sample Apple products..."
        
        # iPhone 15 Pro
        $WP_CLI wc product create \
            --name="iPhone 15 Pro 128GB" \
            --type="simple" \
            --regular_price="129990" \
            --sku="IPHONE15PRO128" \
            --description="iPhone 15 Pro с титановым дизайном, чипом A17 Pro и усовершенствованной камерной системой Pro. Доступен в четырех великолепных цветах." \
            --short_description="Новый iPhone 15 Pro с титановым корпусом и чипом A17 Pro" \
            --categories="[{\"id\": 1}]" \
            --status="publish" \
            --manage_stock=true \
            --stock_quantity=10 \
            --weight="0.187" \
            --user=1 \
            --allow-root >/dev/null
        
        # MacBook Air M3
        $WP_CLI wc product create \
            --name="MacBook Air 13\" M3 256GB" \
            --type="simple" \
            --regular_price="144990" \
            --sku="MACBOOKAIR13M3256" \
            --description="MacBook Air 13\" с чипом M3 обеспечивает исключительную производительность и до 18 часов автономной работы." \
            --short_description="Ультратонкий MacBook Air с чипом M3" \
            --categories="[{\"id\": 2}]" \
            --status="publish" \
            --manage_stock=true \
            --stock_quantity=5 \
            --weight="1.24" \
            --user=1 \
            --allow-root >/dev/null
        
        # iPad Pro 11"
        $WP_CLI wc product create \
            --name="iPad Pro 11\" M4 128GB Wi-Fi" \
            --type="simple" \
            --regular_price="94990" \
            --sku="IPADPRO11M4128" \
            --description="iPad Pro 11\" с чипом M4, дисплеем Ultra Retina XDR и поддержкой Apple Pencil Pro." \
            --short_description="Мощный iPad Pro с чипом M4" \
            --categories="[{\"id\": 3}]" \
            --status="publish" \
            --manage_stock=true \
            --stock_quantity=8 \
            --weight="0.444" \
            --user=1 \
            --allow-root >/dev/null
        
        # Apple Watch Series 9
        $WP_CLI wc product create \
            --name="Apple Watch Series 9 GPS 41mm" \
            --type="simple" \
            --regular_price="44990" \
            --sku="WATCHS9GPS41" \
            --description="Apple Watch Series 9 с чипом S9, ярким дисплеем и новыми возможностями для здоровья." \
            --short_description="Умные часы Apple Watch Series 9" \
            --categories="[{\"id\": 4}]" \
            --status="publish" \
            --manage_stock=true \
            --stock_quantity=15 \
            --weight="0.032" \
            --user=1 \
            --allow-root >/dev/null
        
        # AirPods Pro 2
        $WP_CLI wc product create \
            --name="AirPods Pro (2-го поколения)" \
            --type="simple" \
            --regular_price="24990" \
            --sku="AIRPODSPRO2" \
            --description="AirPods Pro с активным шумоподавлением нового уровня, Пространственным аудио и зарядным футляром MagSafe." \
            --short_description="Беспроводные наушники с активным шумоподавлением" \
            --categories="[{\"id\": 5}]" \
            --status="publish" \
            --manage_stock=true \
            --stock_quantity=20 \
            --weight="0.061" \
            --user=1 \
            --allow-root >/dev/null
        
        # Magic Keyboard
        $WP_CLI wc product create \
            --name="Magic Keyboard для iPad Pro 11\"" \
            --type="simple" \
            --regular_price="34990" \
            --sku="MAGICKEYBOARD11" \
            --description="Magic Keyboard с трекпадом превращает iPad Pro в универсальное устройство для работы." \
            --short_description="Клавиатура с трекпадом для iPad Pro" \
            --categories="[{\"id\": 6}]" \
            --status="publish" \
            --manage_stock=true \
            --stock_quantity=12 \
            --weight="0.601" \
            --user=1 \
            --allow-root >/dev/null
        
        log_success "Created sample Apple products"
    else
        log_success "Products already exist, skipping sample creation"
    fi
}

main() {
    echo -e "${BLUE}🛍️  Starting Ultrastore WordPress Setup${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Load environment variables
    if [ -f .env ]; then
        export $(grep -v '^#' .env | xargs)
    fi
    
    check_services
    wait_for_wordpress
    install_wordpress
    remove_default_themes
    setup_ultrastore_theme
    remove_default_plugins
    install_woocommerce
    configure_woocommerce
    configure_wordpress_for_headless
    update_translations
    create_sample_content
    
    # Get final configuration for output
    WP_DOMAIN="${WP_DOMAIN:-localhost}"
    WP_URL="${WP_URL:-${WP_DOMAIN}}"
    WP_TITLE="${WP_TITLE:-Ultrastore}"
    STORE_EMAIL="${STORE_EMAIL:-shop@${WP_DOMAIN}}"
    PROTOCOL="${WP_PROTOCOL:-https}"
    
    echo ""
    echo -e "${GREEN}🎉 ${WP_TITLE} setup completed successfully!${NC}"
    echo -e "${BLUE}🛍️  Store: ${WP_TITLE} - Магазин техники Apple в Санкт-Петербурге${NC}"
    echo -e "${BLUE}🌐 Domain: ${WP_DOMAIN}${NC}"
    echo -e "${BLUE}📍 Address: Лиговский проспект, 73, офис 506, 5 этаж, СПб 191040${NC}"
    echo -e "${BLUE}📧 Email: ${STORE_EMAIL}${NC}"
    echo -e "${BLUE}📝 WordPress Admin: ${PROTOCOL}://${WP_URL}/wp-admin${NC}"
    echo -e "${BLUE}👤 Credentials: ${WP_ADMIN_USER:-admin} / ${WP_ADMIN_PASS:-admin}${NC}"
    echo -e "${BLUE}🔌 REST API: ${PROTOCOL}://${WP_URL}/wp-json/${NC}"
    echo -e "${BLUE}🛒 WooCommerce API: ${PROTOCOL}://${WP_URL}/wp-json/wc/v3/${NC}"
    echo -e "${BLUE}💰 Currency: Russian Ruble (RUB)${NC}"
    echo -e "${BLUE}📦 Sample Products: iPhone, MacBook, iPad, Apple Watch, AirPods${NC}"
    echo ""
}

# Run main function
main "$@"
