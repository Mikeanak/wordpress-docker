FROM wordpress:6.6-php8.2-apache

# Install dependencies and wp-cli
RUN set -eux; \
    apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            wget ca-certificates less vim-tiny python3 python3-yaml default-mysql-client apache2-utils; \
    rm -rf /var/lib/apt/lists/*; \
    wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
    chmod +x /usr/local/bin/wp

# Copy WordPress into dedicated directory and set Apache docroot
RUN set -eux; \
    rm -rf /var/www/html; \
    mkdir -p /var/www/wordpress; \
    cp -R /usr/src/wordpress/. /var/www/wordpress; \
    ln -s /var/www/wordpress /var/www/html

# Download phpMyAdmin
ENV PHPMYADMIN_VERSION=5.2.1
RUN set -eux; \
    wget -O /tmp/pma.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz; \
    mkdir -p /var/www/phpmyadmin; \
    tar -xzf /tmp/pma.tar.gz -C /var/www/phpmyadmin --strip-components=1; \
    rm /tmp/pma.tar.gz

# Generate phpMyAdmin basic auth password at build time
RUN set -eux; \
    PMA_PASS=$(python3 -c "import secrets,string; alphabet=string.ascii_letters+string.digits; print(''.join(secrets.choice(alphabet) for _ in range(32)))"); \
    echo "Generated phpMyAdmin password for user 'admin': ${PMA_PASS}"; \
    echo "${PMA_PASS}" > /opt/pma-admin-password.txt; \
    htpasswd -bc /etc/apache2/.pma_htpasswd admin "${PMA_PASS}"; \
    PMA_BLOW=$(python3 -c "import secrets,string; alphabet=string.ascii_letters+string.digits; print(''.join(secrets.choice(alphabet) for _ in range(32)))"); \
    echo "${PMA_BLOW}" > /opt/pma-blowfish-secret.txt

# Apache configuration for dual vhosts
RUN set -eux; \
    a2enmod rewrite headers; \
    echo "Listen 8081" >> /etc/apache2/ports.conf

COPY apache/wordpress.conf /etc/apache2/sites-available/wordpress.conf
COPY apache/phpmyadmin.conf /etc/apache2/sites-available/phpmyadmin.conf
RUN set -eux; \
    a2dissite 000-default; \
    a2ensite wordpress phpmyadmin

# Content and scripts
COPY content/ /opt/content/
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

ENV WP_PATH=/var/www/wordpress \
    CONTENT_DIR=/opt/content \
    PMA_DIR=/var/www/phpmyadmin \
    ENV_FILE=/config/env.yaml

# Expose phpMyAdmin port
EXPOSE 8081

# Entry point
COPY scripts/entrypoint.sh /usr/local/bin/custom-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["apache2-foreground"]
