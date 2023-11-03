FROM  php:8.2.5-fpm

ENV USER=www-data
ENV GROUP=www-data

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    cron \
    supervisor \
    libpq-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip pdo pdo_pgsql

# Get latest Composer
COPY --from=composer:lts /usr/bin/composer /usr/local/bin/composer

# Install Supervisor and create log directory
RUN mkdir -p /var/log/supervisor && mkdir -p /var/run/supervisor 
COPY docker/supervisord.conf /etc/supervisor/supervisord.conf
COPY docker/config/tambahan.ini /usr/local/etc/php/conf.d/tambahan.ini
COPY docker/config/tambahan-fpm.ini /usr/local/etc/php-fpm.d/tambahan.ini

# Setup working directory
WORKDIR /app

#laravel scheduler cronjob
RUN echo "* * * * * ${USER} /usr/local/bin/php /app/artisan schedule:run >> /dev/null 2>&1"  >> /etc/cron.d/laravel-scheduler
RUN chmod 0644 /etc/cron.d/laravel-scheduler

# Create User and Group
#RUN groupadd -g 1000 ${GROUP} && useradd -u 1000 -ms /bin/bash -g ${GROUP} ${USER}

# #Grant Permissions
RUN chown -R ${USER}:${GROUP} /app /var/log/supervisor /var/run/supervisor

# Copy permission to selected user
COPY --chown=${USER}:${GROUP} . .

# Select User
#USER ${USER}

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
