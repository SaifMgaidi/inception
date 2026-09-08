#!/bin/bash

# Arreter le script en cas d'erreur
set -e

# On demarre temporairement le service mariadb
service mariadb start

# On attend que le serveur de mariaDB soit pret pour executer des commandes
while ! mysqladmin ping --silent;do
    sleep 1
done

# Creation de la base de donnee (si elle n'existe pas deja)
mysql -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"

# Creation du premier utilisateur
mysql -e "CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';"

# On donne tous les droits a notre utilisateur.
mysql -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';"

# On modifie le mot de passe de l'administrateur supreme (le root)
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"

# On eteint proprement le service temporaire
mysqladmin -u root -p${SQL_ROOT_PASSWORD} shutdown

# On relance MariaDB au premier plan en remplacant le processus actuel
exec mysqld_safe
