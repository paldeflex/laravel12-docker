FROM php:8.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
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
    linux-headers-generic || true

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql pgsql mbstring exif pcntl bcmath gd zip intl opcache

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Xdebug extension
RUN pecl install xdebug && docker-php-ext-enable xdebug

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
    && echo "upload_max_filesize = 64M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
    && echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
    && echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/docker-php-memory.ini

WORKDIR /var/www/html

RUN groupadd -g 1000 www && useradd -u 1000 -ms /bin/bash -g www www

USER www