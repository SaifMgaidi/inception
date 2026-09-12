
FROM debian:bookworm

# Mise a jour des paquets et installation de NGINX et d'OpenSSL
RUN apt-get update -y && apt-get install -y nginx openssl

# creation du dossier qui va contenir notre certificat
RUN mkdir -p /etc/nginx/ssl

# Génération du certificat SSL auto-signé
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=sm-gaidi.42.fr/UID=sm-gaidi"

# Creation du dossier necessaire au bon fonctionnement de nginx
RUN mkdir -p /var/run/nginx

# Remplacement du fichier de configuration de NGINX par default, par la notre
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Nous rendons le port 443 accessible a l'exterieur du conteneur
EXPOSE 443

# Lancement de NGINX au premier plan (PID 1)
ENTRYPOINT ["nginx", "-g", "daemon off;"]
