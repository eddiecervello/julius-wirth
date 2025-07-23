FROM uselagoon/php-7.4-cli-drupal:latest

# Copy the Drupal codebase
COPY . /app

# Ensure the correct ownership and permissions
RUN fix-permissions /app

# Install Drush if not already available
RUN composer global require drush/drush:^8.4

# Create directories and set permissions
RUN mkdir -p /app/sites/default/files \
    && mkdir -p /app/sites/default/files/backup \
    && fix-permissions /app/sites/default/files

# Set working directory
WORKDIR /app

# Health check script
RUN echo '#!/bin/bash\ndrush status' > /app/healthcheck.sh \
    && chmod +x /app/healthcheck.sh

# Set the default command
CMD ["/sbin/tini", "--", "/lagoon/entrypoints.sh", "/bin/bash"]