FROM ubuntu:20.04 AS builder

LABEL maintainer Naba Das <hello@get-deck.com>
ENV PHP_VERSION=7.4
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt -y install software-properties-common && add-apt-repository ppa:ondrej/php -y

# install support package
RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends --no-install-suggests && \
    apt-get install software-properties-common -y --no-install-recommends --no-install-suggests && \
    apt-get update


RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    nginx \
    ca-certificates \
    gettext \
    mc \
    libmcrypt-dev  \
    libicu-dev \
    libcurl4-openssl-dev \
    mysql-client \
    libldap2-dev \
    libfreetype6-dev \
    libfreetype6 \
    curl \
    sudo


# exts
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    php${PHP_VERSION} \
    php${PHP_VERSION}-dev \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mongodb \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-amqp \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-xmlrpc \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-mongodb \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-redis && \
    echo "extension=apcu.so" | tee -a /etc/php/${PHP_VERSION}/mods-available/cache.ini
#    php-mcrypt \

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Install node.js
RUN apt install -y gpg-agent && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt update && apt install -y nodejs yarn

# set timezone Europe/Moscow
RUN cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& ln -sf /dev/stderr /var/log/php${PHP_VERSION}-fpm.log

RUN rm -f /etc/nginx/sites-enabled/*
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

# COPY ./www/index.php /var/www/public/
RUN mkdir -p /run/php && touch /run/php/php${PHP_VERSION}-fpm.sock && touch /run/php/php${PHP_VERSION}-fpm.pid
# RUN setcap cap_net_bind_service=ep /usr/sbin/nginx
# RUN chown -R www-data:www-data /run/php
# RUN chown -R www-data:www-data /run
# RUN chown -R www-data:www-data /etc/nginx
# RUN chown -R www-data:www-data /var/log/nginx
# RUN chown -R www-data:www-data /var/lib/nginx/
# RUN chown -R www-data:www-data /var/lib/nginx

COPY entrypoint.sh /entrypoint.sh
FROM scratch
COPY --from=builder / /

WORKDIR /var/www/
RUN chmod +x /entrypoint.sh
RUN chown -R www-data:www-data /run/php
RUN chown -R www-data:www-data /run
RUN chown -R www-data:www-data /etc/nginx
RUN chown -R www-data:www-data /var/log/nginx
RUN chown -R www-data:www-data /var/lib/nginx/
RUN echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# USER www-data
EXPOSE 80
CMD ["/entrypoint.sh"]
