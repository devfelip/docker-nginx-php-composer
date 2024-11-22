FROM debian:bookworm-slim

LABEL maintainer="Felipe Cavalcanti"

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND=noninteractive
ENV NGINX_VERSION=1.27.2-1~bookworm
ENV php_conf=/etc/php/8.0/fpm/php.ini
ENV fpm_conf=/etc/php/8.0/fpm/pool.d/www.conf
ENV COMPOSER_VERSION=2.8.3

# Install Basic Requirements
RUN buildDeps='wget gcc make autoconf libc-dev libmemcached-dev libmagickwand-dev zlib1g-dev pkg-config' \
    && set -x \
    && apt-get update \
    && apt-get install --no-install-recommends $buildDeps --no-install-suggests -q -y gnupg2 dirmngr curl apt-transport-https lsb-release ca-certificates \
    && \
    NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
	  found=''; \
	  for server in \
        hkp://keyserver.ubuntu.com:80 \
        pgp.mit.edu \
	  ; do \
		  echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
		  apt-key adv --batch --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
	  done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
    echo "deb http://nginx.org/packages/mainline/debian/ bookworm nginx" >> /etc/apt/sources.list \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
            apt-utils \
            nano \
            zip \
            unzip \
            python3-pip \
            python3-setuptools \
            git \
            libmemcached11 \
            libaio1 \
            nginx=${NGINX_VERSION} \
            php8.0-fpm \
            php8.0-cli \
            php8.0-bcmath \
            php8.0-dev \
            php8.0-common \
            php8.0-opcache \
            php8.0-readline \
            php8.0-mbstring \
            php8.0-curl \
            php8.0-gd \
            php8.0-imagick \
            php8.0-mysql \
            php8.0-zip \
            php8.0-pgsql \
            php8.0-intl \
            php8.0-xml \
            php-pear \
    && pecl -d php_suffix=8.0 install -o -f redis memcached

    # Install Oracle Instant Client + SDK https://www.oracle.com/br/database/technologies/instant-client/linux-x86-64-downloads.html
    RUN curl -L https://download.oracle.com/otn_software/linux/instantclient/2360000/instantclient-basiclite-linux.x64-23.6.0.24.10.zip -o instantclient.zip \
    && unzip instantclient.zip "instantclient_23_6/*" -d /usr/lib/oracle/ \
    && rm instantclient.zip \
    && curl -L https://download.oracle.com/otn_software/linux/instantclient/2360000/instantclient-sdk-linux.x64-23.6.0.24.10.zip -o instantclient-sdk.zip \
    && unzip instantclient-sdk.zip "instantclient_23_6/*" -d /usr/lib/oracle/ \
    && rm instantclient-sdk.zip \
    && echo /usr/lib/oracle/instantclient_23_6 > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig
    
    ENV LD_LIBRARY_PATH=/usr/lib/oracle/instantclient_23_6

    # Instalar o driver OCI8 do PHP https://pecl.php.net/package/pdo_oci | https://pecl.php.net/package/oci8
    RUN curl -sSL https://pecl.php.net/get/oci8-3.0.1.tgz | tar xz \
    && cd oci8-3.0.1 \
    && phpize \
    && ./configure --with-oci8=instantclient,/usr/lib/oracle/instantclient_23_6 \
    && make && make install \
    && echo "extension=oci8.so" > /etc/php/8.0/cli/conf.d/20-oci8.ini \
    && echo "extension=oci8.so" > /etc/php/8.0/fpm/conf.d/20-oci8.ini
    
    RUN mkdir -p /run/php \
    && pip install --break-system-packages wheel \
    && pip install --break-system-packages supervisor \
    && pip install --break-system-packages git+https://github.com/coderanger/supervisor-stdout \
    && echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && rm -rf /etc/nginx/conf.d/default.conf \
    && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} \
    && sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} \
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/8.0/fpm/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} \
    && sed -i -e "s/www-data/nginx/g" ${fpm_conf} \
    && sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} \
    && echo "extension=redis.so" > /etc/php/8.0/mods-available/redis.ini \
    && echo "extension=memcached.so" > /etc/php/8.0/mods-available/memcached.ini \
    && echo "extension=imagick.so" > /etc/php/8.0/mods-available/imagick.ini \
    && ln -sf /etc/php/8.0/mods-available/redis.ini /etc/php/8.0/fpm/conf.d/20-redis.ini \
    && ln -sf /etc/php/8.0/mods-available/redis.ini /etc/php/8.0/cli/conf.d/20-redis.ini \
    && ln -sf /etc/php/8.0/mods-available/memcached.ini /etc/php/8.0/fpm/conf.d/20-memcached.ini \
    && ln -sf /etc/php/8.0/mods-available/memcached.ini /etc/php/8.0/cli/conf.d/20-memcached.ini \
    && ln -sf /etc/php/8.0/mods-available/imagick.ini /etc/php/8.0/fpm/conf.d/20-imagick.ini \
    && ln -sf /etc/php/8.0/mods-available/imagick.ini /etc/php/8.0/cli/conf.d/20-imagick.ini \
    # Install Composer https://getcomposer.org/download/
    && curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
    && rm -rf /tmp/composer-setup.php \
    # Clean up
    && rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove $buildDeps php8.0-dev \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
    
# Supervisor config
COPY ./supervisord.conf /etc/supervisord.conf

# Override nginx's default config
COPY ./default.conf /etc/nginx/conf.d/default.conf

# Override default nginx welcome page
COPY html /usr/share/nginx/html

# Copy Scripts
COPY ./start.sh /start.sh

EXPOSE 80

CMD ["/start.sh"]
