#!/bin/bash
set -e

# 1. Build the db container and generate credentials
DB_CREDS_FILE=local.yaml
DB_CONTAINER=mysql-local
WP_CONTAINER=wordpress-local

# Generate random credentials
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)
MYSQL_PASSWORD=$(openssl rand -base64 16)
MYSQL_USER=wpuser
MYSQL_DATABASE=wordpress

# Write DB credentials to local.yaml
echo "mysql_root_password: $MYSQL_ROOT_PASSWORD" > $DB_CREDS_FILE
echo "mysql_password: $MYSQL_PASSWORD" >> $DB_CREDS_FILE
echo "mysql_user: $MYSQL_USER" >> $DB_CREDS_FILE
echo "mysql_database: $MYSQL_DATABASE" >> $DB_CREDS_FILE

# Generate env.yaml for WordPress container
ENV_FILE=env.yaml
cat > $ENV_FILE <<EOF
db_host: db
db_port: 3306
db_name: $MYSQL_DATABASE
db_user: $MYSQL_USER
db_password: $MYSQL_PASSWORD
site_url: http://localhost:8080
EOF

docker buildx build --load --build-arg MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --build-arg MYSQL_PASSWORD=$MYSQL_PASSWORD --build-arg MYSQL_USER=$MYSQL_USER --build-arg MYSQL_DATABASE=$MYSQL_DATABASE -f Dockerfile.mysql -t $DB_CONTAINER .

# 2. Build the wordpress container and generate phpmyadmin creds
MASTER_KEY_FILE=master_key.txt
PHPMYADMIN_PASSWORD=$(openssl rand -base64 16)
PHPMYADMIN_USER=phpmyadmin

echo "phpmyadmin_user: $PHPMYADMIN_USER" > $MASTER_KEY_FILE
echo "phpmyadmin_password: $PHPMYADMIN_PASSWORD" >> $MASTER_KEY_FILE

docker buildx build --load --build-arg PHPMYADMIN_USER=$PHPMYADMIN_USER --build-arg PHPMYADMIN_PASSWORD=$PHPMYADMIN_PASSWORD -t $WP_CONTAINER .

# 3. Generate docker-compose file for local setup
COMPOSE_FILE=local_setup.yaml
cat > $COMPOSE_FILE <<EOF
services:
  db:
    image: $DB_CONTAINER
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
      MYSQL_DATABASE: $MYSQL_DATABASE
      MYSQL_USER: $MYSQL_USER
      MYSQL_PASSWORD: $MYSQL_PASSWORD
    ports:
      - "3306:3306"
  wordpress:
    image: $WP_CONTAINER
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: $MYSQL_USER
      WORDPRESS_DB_PASSWORD: $MYSQL_PASSWORD
      WORDPRESS_DB_NAME: $MYSQL_DATABASE
      PHPMYADMIN_USER: $PHPMYADMIN_USER
      PHPMYADMIN_PASSWORD: $PHPMYADMIN_PASSWORD
    ports:
      - "8080:80"
      - "8081:8081"
    depends_on:
      - db
    volumes:
      - ./env.yaml:/config/env.yaml:ro
EOF

# 4. Start the stack and print the WordPress URL
docker compose -f local_setup.yaml up -d
WP_URL="http://localhost:8080"
echo "WordPress is ready! Open $WP_URL in your browser."
docker compose -f local_setup.yaml up -d
