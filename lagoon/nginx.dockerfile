FROM uselagoon/nginx-drupal:latest

# Copy custom Nginx configuration if exists
COPY lagoon/nginx.conf /etc/nginx/conf.d/000-default.conf

# Copy the application code from CLI image
ARG CLI_IMAGE
COPY --from=$CLI_IMAGE /app /app

# Ensure proper permissions
RUN fix-permissions /app