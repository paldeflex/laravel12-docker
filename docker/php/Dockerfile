FROM php:8.4-fpm

# Build arguments for user/group ID (allows customization for different host systems)
ARG UID=1000
ARG GID=1000

# Install system dependencies, PHP extensions, and cleanup in a single layer
# This reduces image size by:
# - Using --no-install-recommends to skip optional packages
# - Removing build dependencies after compilation
# - Cleaning apt cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    nano \
    $PHPIZE_DEPS \
    # Install PHP extensions
    && docker-php-ext-install pdo pdo_pgsql pgsql mbstring exif pcntl bcmath gd zip intl opcache \
    # Install Redis extension
    && pecl install redis && docker-php-ext-enable redis \
    # Install Xdebug extension
    && pecl install xdebug && docker-php-ext-enable xdebug \
    # Remove build dependencies to reduce image size
    && apt-get purge -y --auto-remove $PHPIZE_DEPS \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy Composer from official image (pinned version for reproducibility)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy Xdebug configuration
COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Configure PHP settings
RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
    && echo "upload_max_filesize = 64M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
    && echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
    && echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/docker-php-memory.ini

WORKDIR /var/www/html

# Create non-root user with configurable UID/GID
RUN groupadd -g ${GID} www && useradd -u ${UID} -ms /bin/bash -g www www

USER www
