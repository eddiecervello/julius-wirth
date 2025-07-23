FROM uselagoon/php-7.4-fpm:latest

# Copy the application code from CLI image
ARG CLI_IMAGE
COPY --from=$CLI_IMAGE /app /app

# Install additional PHP extensions if needed
# RUN docker-php-ext-install gd mysqli pdo_mysql

# Configure PHP settings for Drupal 7
RUN echo 'memory_limit = 256M\n\
max_execution_time = 120\n\
max_input_vars = 3000\n\
post_max_size = 32M\n\
upload_max_filesize = 32M\n\
max_file_uploads = 20\n\
date.timezone = "UTC"\n\
session.gc_maxlifetime = 86400\n\
session.gc_probability = 1\n\
session.gc_divisor = 100' >> /usr/local/etc/php/conf.d/drupal.ini

# Ensure proper permissions
RUN fix-permissions /app