#!/bin/bash

# arret du script en cas d'erreur
set -e

# On attend que MariaDB soit pret
    while ! mysqladmin ping -h"${WORDPRESS_DB_HOST}" -u"${SQL_USER}" -p"${SQL_PASSWORD}" --silent; do
        sleep 1
    done


if [ ! -f wp-config.php ]; then
    # telecharge les fichiers de wordpress
    wp core download --allow-root --force
    
    # cree le fichier de config, qui permet a wordpress,
    # de savoir comment se connecter a mariaDB.
    wp config create --dbname=${SQL_DATABASE} \
                     --dbuser=${SQL_USER} \
                     --dbpass=${SQL_PASSWORD} \
                     --dbhost=${WORDPRESS_DB_HOST} \
                     --allow-root

    # installation de wordpress + creation de l'administrateur.
    wp core install --url=${DOMAIN_NAME} \
                    --title="le site inception" \
                    --admin_user=${WP_ADMIN_USER} \
                    --admin_password=${WP_ADMIN_PASSWORD} \
                    --admin_email=${WP_ADMIN_EMAIL} \
                    --allow-root
    
    # Creation du second utilisateur
    wp user create ${WP_USER} ${WP_EMAIL} \
                   --user_pass=${WP_PASSWORD} \
                   --role=author \
                   --allow-root
fi

# Creation du dossier temporaire pour PHP-FPM
mkdir -p /run/php

# le dossier de notre site web, change de proprietaire (ce n'est plus root mais nous)
chown -R www-data:www-data /var/www/html

# Execute php-fpm au premier plan
exec php-fpm8.2 -F
