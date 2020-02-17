FROM php:7.3

MAINTAINER maimake <yshxinjian@gmail.com>

# --build-arg timezone=Asia/Shanghai
ARG timezone
# app_env: prod pre test dev
ARG app_env=prod


ENV APP_ENV=${app_env:-"prod"} \
    TIMEZONE=${timezone:-"Asia/Shanghai"} \
    SWOOLE_VERSION=4.4.12 \
    COMPOSER_ALLOW_SUPERUSER=1


# Timezone
RUN set -eux; \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && echo "[Date]\ndate.timezone=${TIMEZONE}" > /usr/local/etc/php/conf.d/timezone.ini


# apt-get install
RUN set -eux; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        iputils-ping telnet net-tools curl zip unzip git wget openssl procps\
        librdkafka-dev \
        libz-dev \
        libssl-dev \
        libnghttp2-dev \
        libpcre3-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
# Clear dev deps
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false


# Install PHP extensions
RUN set -eux; \
    docker-php-ext-install \
        pdo_mysql sockets mysqli gd pcntl \
# Install redis extension
    && pecl install redis \
    && docker-php-ext-enable redis \
# Install mongodb extension
    && pecl install mongodb \
    && docker-php-ext-enable mongodb \
# Install rdkafka extension
    && pecl install rdkafka \
    && docker-php-ext-enable rdkafka \
# Install swoole extension
    && wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-mysqlnd --enable-sockets --enable-openssl --enable-http2 \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole \
# Install composer
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer self-update --clean-backups \
# Clear dev deps
    && rm -rf /tmp/pear

# Install hiredis
RUN set -eux; \
    mkdir -p /opt/hiredis \
    && wget -O /opt/hiredis.tar.gz https://github.com/redis/hiredis/archive/v0.14.0.tar.gz \
    && tar -xzvf /opt/hiredis.tar.gz --strip-components 1 -C /opt/hiredis \
    && cd /opt/hiredis \
    && make && make install && ldconfig \
    && cd / && rm -Rf /opt/hiredis*


