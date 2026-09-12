#!/bin/bash
set -e

# On verifie si le dossier de la base de donnees existe deja dans le volume
if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    
    # On demarre temporairement le service mariadb pour le configurer
    service mariadb start

    # On attend que le serveur soit pret
    while ! mysqladmin ping --silent; do
        sleep 1
    done

    # Creation et configuration
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
    mysql -e "CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"
    
    # On applique les droits
    mysql -e "FLUSH PRIVILEGES;"

    # On eteint proprement le service temporaire avec le nouveau mot de passe
    mysqladmin -u root -p${SQL_ROOT_PASSWORD} shutdown
fi

# On lance MariaDB au premier plan (qu'il soit fraichement installe ou deja existant)
exec mysqld_safe
