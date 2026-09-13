
# On choisit notre image Debian
FROM debian:bookworm

# On met a jour la liste des paquets et on installe le serveur mariadb
RUN apt-get update -y && apt-get install mariadb-server -y

# On copie notre fichier de configuration vers le bon dossier a l'interieur de l'image
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf


# On copie notre script de demmarage
COPY tools/mariadb.sh /usr/local/bin/mariadb.sh

# On donne les droits d'execution a notre script de demmarage
RUN chmod +x /usr/local/bin/mariadb.sh

# On definit le script qui va s'executer au demmarage du conteneur.
ENTRYPOINT ["/usr/local/bin/mariadb.sh"]