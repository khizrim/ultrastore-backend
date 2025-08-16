<?php
/**
 * Ultrastore Headless Theme Functions
 * Minimal headless theme optimized for API access
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

// Theme setup
add_action('after_setup_theme', function () {
    // Basic WordPress features
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    
    // WooCommerce support
    add_theme_support('woocommerce');
    add_theme_support('wc-product-gallery-zoom');
    add_theme_support('wc-product-gallery-lightbox');
    add_theme_support('wc-product-gallery-slider');
});

// Enable CORS headers for API access
add_action('rest_api_init', function () {
    remove_filter('rest_pre_serve_request', 'rest_send_cors_headers');
    add_filter('rest_pre_serve_request', function ($value) {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-WP-Nonce');
        
        if ('OPTIONS' === $_SERVER['REQUEST_METHOD']) {
            status_header(200);
            exit;
        }
        
        return $value;
    });
});

// Keep permalinks endpoints working without front templates
add_action('init', function () {
    // Ensure proper permalink structure for API endpoints
});

// Disable unnecessary features for headless setup
add_action('init', function () {
    // Remove unnecessary admin bar for headless use
    if (!is_admin()) {
        show_admin_bar(false);
    }
});
