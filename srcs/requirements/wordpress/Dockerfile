
# On utilise Debian 12
FROM debian:bookworm

# On met a jour la liste des parquets,
# et on installe les dependances.
RUN apt-get update -y && apt-get install -y \
php-fpm \
php-mysql \
curl \
mariadb-client

# On telecharge wp-cli (il nous permettra d'installer wordpress en ligne de commande)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

# On donne les permissions d'execution a wp-cli
RUN chmod +x wp-cli.phar

# On deplace wp-cli.phar en l'appelant maintenant seulement wp
RUN mv wp-cli.phar /usr/local/bin/wp

# On cree le dossier qui va accueillir les fichiers de notre site.
RUN mkdir -p /var/www/html

# Copie du fichier de configuration dans notre image.
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copie du script d'initialisation dans lre repertoire bin
COPY tools/wordpress.sh /usr/local/bin/wordpress.sh

# On donne la permission d'execution de notre script
RUN chmod +x /usr/local/bin/wordpress.sh

# Notre dossier html devient le repertoire courant pour nos futures commandes
WORKDIR /var/www/html

# Notre script devient le point d'entree du conteneur wordpress
ENTRYPOINT ["/usr/local/bin/wordpress.sh"]
