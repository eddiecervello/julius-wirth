# # Use PHP 7.4 with Apache (matches Lando config)
FROM php:7.4-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    vim \
    mariadb-client \
    libxml2-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-install -j$(nproc) iconv mysqli pdo_mysql \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip opcache xml mbstring

# Install additional PHP extensions Drupal 7 likes
RUN pecl install uploadprogress && docker-php-ext-enable uploadprogress

# Enable Apache modules
RUN a2enmod rewrite headers expires

# Set recommended PHP.ini settings
RUN { \
    echo 'memory_limit = ${PHP_MEMORY_LIMIT}'; \
    echo 'upload_max_filesize = 32M'; \
    echo 'post_max_size = 32M'; \
    echo 'max_execution_time = ${PHP_MAX_EXECUTION_TIME}'; \
    echo 'max_input_vars = 3000'; \
    echo 'date.timezone = UTC'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.interned_strings_buffer = 8'; \
    echo 'opcache.max_accelerated_files = 4000'; \
    echo 'opcache.revalidate_freq = 60'; \
    echo 'opcache.fast_shutdown = 1'; \
    echo 'session.gc_maxlifetime = 200000'; \
    echo 'session.cookie_lifetime = 2000000'; \
  } > /usr/local/etc/php/conf.d/drupal-recommended.ini

# Copy custom virtual host configuration
COPY docker-config/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Set up the entrypoint script
COPY docker-config/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Make sure files are writable by Apache
RUN chown -R www-data:www-data /var/www/html

# Expose port 80
EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
