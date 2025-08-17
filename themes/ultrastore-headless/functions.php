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

// ==== CORS for REST + AJAX (headless) ====
add_action('init', function () {
  // Always allow localhost for local dev
  $dev_origins = [
    'http://localhost:3000',
    'http://localhost:8080',
  ];

  // Dynamic check for *.ultrastore.khizrim.online + root
  $is_allowed = function (string $origin): bool {
    if (preg_match('#^https?://([a-z0-9-]+\.)?ultrastore\.khizrim\.online$#i', $origin)) {
      return true;
    }
    return false;
  };

  // Filter for WP allowed origins
  add_filter('allowed_http_origins', function ($origins) use ($dev_origins) {
    return array_merge($origins, $dev_origins);
  });

  // REST API CORS
  add_action('rest_api_init', function () use ($dev_origins, $is_allowed) {
    remove_filter('rest_pre_serve_request', 'rest_send_cors_headers');

    add_filter('rest_pre_serve_request', function ($value) use ($dev_origins, $is_allowed) {
      $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

      if ($origin && ($is_allowed($origin) || in_array($origin, $dev_origins, true))) {
        header("Access-Control-Allow-Origin: {$origin}");
        header('Vary: Origin');
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-WP-Nonce, X-Requested-With');
        header('Access-Control-Expose-Headers: X-WP-Total, X-WP-TotalPages, Link, X-WC-Total, X-WC-TotalPages');
      }

      if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        status_header(204);
        exit;
      }

      return $value;
    });
  });

  // admin-ajax.php CORS
  add_action('admin_init', function () use ($dev_origins, $is_allowed) {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    if ($origin && ($is_allowed($origin) || in_array($origin, $dev_origins, true))) {
      header("Access-Control-Allow-Origin: {$origin}");
      header('Vary: Origin');
      header('Access-Control-Allow-Credentials: true');
      header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
      header('Access-Control-Allow-Headers: Content-Type, Authorization, X-WP-Nonce, X-Requested-With');

      if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        status_header(204);
        exit;
      }
    }
  });
});

// ==== Frontend URL Configuration ====
add_action('init', function () {
  // Determine frontend URL based on environment
  $frontend_url = '';
  
  // Check if we're in production (based on site URL)
  $site_url = get_site_url();
  if (strpos($site_url, 'wp.ultrastore.khizrim.online') !== false) {
    // Production frontend
    $frontend_url = 'https://ultrastore.khizrim.online';
  } else {
    // Local development frontend
    $frontend_url = 'http://localhost:3000';
  }
  
  // Make frontend URL available globally
  if (!defined('FRONTEND_URL')) {
    define('FRONTEND_URL', $frontend_url);
  }
});

