# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM php:7.4-apache-buster

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# install the PHP extensions we need
RUN set -ex; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
	;


# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html

# https://www.drupal.org/node/3060/release
ENV DRUPAL_VERSION 8.7.2
ENV DRUPAL_MD5 fad034b129695c5066e892cd7cb02a11

RUN apt-get update && apt-get install -y \
  git \
  unzip \
  wget \
  curl \
  libcurl4-openssl-dev

RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libzip-dev
RUN docker-php-ext-install zip

RUN apt-get install -y rsync

# Set timezone.
ENV PHP_TIMEZONE America/Sao_Paulo
RUN echo "date.timezone = \"$PHP_TIMEZONE\"" > /usr/local/etc/php/conf.d/timezone.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN echo 'export PATH="$PATH:/root/.composer/vendor/bin"' >> $HOME/.bashrc

# Install drush
RUN wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.4.2/drush.phar && \
    chmod +x drush.phar && \
    mv drush.phar /usr/local/bin/drush

ENV NODE_VERSION=12.16.1
# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 12.16.1

# install nvm
ENV NVM_DIR /usr/local/nvm
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash
ENV NODE_VERSION v12.16.1
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"

ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

RUN npm i -g yarn

RUN npm install -g gulp

# ADD package.json yarn.lock /tmp/
# ADD .yarn-cache.tgz /

# RUN cd /tmp && yarn
# RUN mkdir -p /service && cd /service && ln -s /tmp/node_modules

# COPY . /service
# WORKDIR /service


# Copy repo files
COPY . .

ENV COMPOSER_HOME '/composer-cache'
ENV npm_config_cache '/node-cache'

RUN  npm config set cache /node-cache --global
RUN  yarn config set cache-folder /node-cache
RUN  npm --global cache verify

#ENV COMPOSER_ALLOW_SUPERUSER 1
#RUN composer install --no-dev



