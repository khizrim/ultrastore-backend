# Используем официальный образ WordPress как базовый
FROM wordpress:6.6-apache

# Устанавливаем WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Устанавливаем необходимые зависимости для WP-CLI
RUN apt-get update && \
    apt-get install -y \
    less \
    default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Создаем пользователя для wp-cli (wp-cli не должен запускаться от root)
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

# Убеждаемся что WP-CLI может работать в контейнере
ENV WP_CLI_ALLOW_ROOT=1

# WP-CLI будет создавать wp-config.php автоматически

# Устанавливаем права доступа
RUN chown -R www-data:www-data /var/www/html