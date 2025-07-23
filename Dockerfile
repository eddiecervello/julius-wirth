# Production Dockerfile for Julius Wirth Drupal 7 Website
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
    python3-pip \
    dnsutils \
    iputils-ping \
    telnet \
    && pip3 install awscli \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-install -j$(nproc) iconv mysqli pdo_mysql \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip opcache xml mbstring

# Install additional PHP extensions Drupal 7 likes
RUN pecl install uploadprogress && docker-php-ext-enable uploadprogress

# Enable Apache modules
RUN a2enmod rewrite headers expires env

# Set recommended PHP.ini settings with proper error logging
RUN { \
    echo 'memory_limit = 256M'; \
    echo 'upload_max_filesize = 32M'; \
    echo 'post_max_size = 32M'; \
    echo 'max_execution_time = 120'; \
    echo 'max_input_vars = 3000'; \
    echo 'date.timezone = UTC'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.interned_strings_buffer = 8'; \
    echo 'opcache.max_accelerated_files = 4000'; \
    echo 'opcache.revalidate_freq = 60'; \
    echo 'opcache.fast_shutdown = 1'; \
    echo 'session.gc_maxlifetime = 200000'; \
    echo 'session.cookie_lifetime = 2000000'; \
    echo 'error_log = /dev/stderr'; \
    echo 'log_errors = On'; \
    echo 'display_errors = On'; \
    echo 'display_startup_errors = On'; \
    echo 'variables_order = EGPCS'; \
    echo 'auto_globals_jit = Off'; \
  } > /usr/local/etc/php/conf.d/drupal-recommended.ini

# Create environment variable script for Apache
RUN echo '#!/bin/bash' > /usr/local/bin/apache-env-setup.sh && \
    echo 'echo "Setting up environment variables for Apache..."' >> /usr/local/bin/apache-env-setup.sh && \
    echo 'printenv | grep -E "^(DRUPAL_|DB_|BASE_URL|ENVIRONMENT)" > /etc/apache2/envvars.custom' >> /usr/local/bin/apache-env-setup.sh && \
    echo 'source /etc/apache2/envvars.custom' >> /usr/local/bin/apache-env-setup.sh && \
    chmod +x /usr/local/bin/apache-env-setup.sh

# Add environment variable loading to Apache startup
RUN echo 'export APACHE_ARGUMENTS="-D FOREGROUND"' >> /etc/apache2/envvars && \
    echo '# Load custom environment variables' >> /etc/apache2/envvars && \
    echo 'if [ -f /etc/apache2/envvars.custom ]; then' >> /etc/apache2/envvars && \
    echo '    source /etc/apache2/envvars.custom' >> /etc/apache2/envvars && \
    echo 'fi' >> /etc/apache2/envvars

# Install Composer and Drush for debugging
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require drush/drush:^8.4 \
    && ln -s ~/.composer/vendor/bin/drush /usr/local/bin/drush \
    && drush --version

# Copy custom virtual host configuration
COPY docker-config/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Set up the entrypoint script
COPY docker-config/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# Copy Drupal files
COPY --chown=www-data:www-data . /var/www/html/

# Remove development and build files that shouldn't be in production container
RUN rm -rf .git .gitignore .lando.yml docker-compose.yml Dockerfile* \
    aws-infrastructure* *.md *.sh *.pem *.json *.txt *.tar.gz \
    && find /var/www/html -name ".DS_Store" -delete \
    && find /var/www/html -name "*.log" -delete

# Make sure files are writable by Apache
RUN chown -R www-data:www-data /var/www/html

# Expose port 80
EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
