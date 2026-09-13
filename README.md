*This project has been created as part of the 42 curriculum by sm-gaidi.*

# Inception

> Projet **42 Inception** — déploiement d'une petite infrastructure web entièrement conteneurisée avec Docker Compose.

## 📖 Présentation

**Inception** consiste à mettre en place une infrastructure composée de plusieurs services Docker, chacun exécuté dans son propre conteneur et construit à partir d'une image Debian personnalisée.

Dans ce projet, l'infrastructure est composée de trois services :

* **NGINX** : serveur web et point d'entrée HTTPS.
* **WordPress + PHP-FPM** : application web.
* **MariaDB** : base de données utilisée par WordPress.

Les services communiquent sur un réseau Docker privé et les données persistantes sont stockées dans des volumes montés sur la machine hôte.

## 🏗️ Architecture

```text
                         HTTPS :443
                             │
                             ▼
                    ┌─────────────────┐
                    │      NGINX      │
                    │    Debian       │
                    │   SSL / HTTPS   │
                    └────────┬────────┘
                             │
                       FastCGI :9000
                             │
                             ▼
                    ┌─────────────────┐
                    │    WORDPRESS    │
                    │  PHP-FPM 8.2   │
                    │    WP-CLI       │
                    └────────┬────────┘
                             │
                         MySQL :3306
                             │
                             ▼
                    ┌─────────────────┐
                    │     MARIADB     │
                    │     Debian      │
                    └─────────────────┘

                    Docker network
                    inception_network
```

### Flux d'une requête

1. Le navigateur contacte `sm-gaidi.42.fr` en HTTPS sur le port `443`.
2. NGINX reçoit la requête et sert les fichiers statiques.
3. Les requêtes PHP sont transmises à PHP-FPM dans le conteneur WordPress via `wordpress:9000`.
4. WordPress communique avec MariaDB via le nom de service Docker `mariadb`.
5. Les données MariaDB et les fichiers WordPress sont conservés dans des volumes persistants.

## 📁 Structure du projet

```text
inception/
├── Makefile
├── README.md
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── mariadb.sh
        │
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        │
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── wordpress.sh
```

La structure actuelle du dépôt contient bien les trois services et leurs fichiers de configuration/scripts associés.

---

# 🐳 Services

## MariaDB

Le conteneur MariaDB est construit depuis `debian:bookworm` et installe le serveur MariaDB avec `apt`.

Le Dockerfile :

* installe MariaDB ;
* copie `50-server.cnf` ;
* configure l'adresse d'écoute de MariaDB ;
* installe le script `mariadb.sh` ;
* utilise ce script comme `ENTRYPOINT`.

### Initialisation

Le script `mariadb.sh` :

1. vérifie si la base existe déjà ;
2. démarre temporairement MariaDB ;
3. attend que MariaDB soit réellement disponible avec `mysqladmin ping` ;
4. crée la base de données ;
5. crée l'utilisateur WordPress ;
6. attribue les privilèges nécessaires ;
7. configure le mot de passe root ;
8. arrête proprement le serveur temporaire ;
9. relance MariaDB au premier plan avec `mysqld_safe`.

Cette attente permet notamment d'éviter d'exécuter des commandes SQL alors que MariaDB n'est pas encore prêt à accepter les connexions.

---

## WordPress

Le conteneur WordPress est construit depuis `debian:bookworm`.

Il installe notamment :

* PHP-FPM ;
* `php-mysql` ;
* `mariadb-client` ;
* `curl` ;
* WP-CLI.

### Initialisation

Le script `wordpress.sh` :

1. attend que MariaDB soit disponible ;
2. télécharge WordPress avec WP-CLI lors de la première initialisation ;
3. crée `wp-config.php` ;
4. configure la connexion à MariaDB ;
5. installe WordPress ;
6. crée le compte administrateur ;
7. crée un second utilisateur avec le rôle `author` ;
8. crée `/run/php` ;
9. attribue les fichiers du site à `www-data` ;
10. lance PHP-FPM au premier plan.

PHP-FPM utilise l'utilisateur `www-data` afin que le processus PHP ne s'exécute pas avec les privilèges root.

---

## NGINX

Le conteneur NGINX est également construit depuis `debian:bookworm`.

Il installe :

* NGINX ;
* OpenSSL.

Un certificat SSL auto-signé est généré lors de la construction de l'image.

NGINX :

* écoute sur le port `443` ;
* utilise HTTPS ;
* accepte TLS 1.2 et TLS 1.3 ;
* sert `/var/www/html` ;
* transmet les requêtes PHP à `wordpress:9000` via FastCGI.

---

# 🔗 Réseau Docker

Les trois services utilisent le réseau :

```text
inception_network
```

Il s'agit d'un réseau Docker de type `bridge`.

Les services communiquent entre eux grâce aux noms de services Docker :

```text
nginx     → wordpress:9000
wordpress → mariadb
```

Aucun port MariaDB ou PHP-FPM n'est exposé directement sur la machine hôte.

Seul le port HTTPS `443` est publié :

```yaml
ports:
  - "443:443"
```

La configuration Compose définit bien un réseau dédié ainsi que les trois services.

---

# 💾 Volumes et persistance

Deux volumes sont utilisés.

## MariaDB

```text
/home/sm-gaidi/data/mariadb
        ↓
/var/lib/mysql
```

Ce volume contient les données de MariaDB.

## WordPress

```text
/home/sm-gaidi/data/wordpress
        ↓
/var/www/html
```

Ce volume contient les fichiers WordPress, notamment :

* `wp-config.php` ;
* les fichiers du site ;
* les fichiers WordPress téléchargés.

Les volumes sont configurés comme des bind mounts vers les dossiers de données de la machine hôte.

Cela permet de conserver les données même lorsque les conteneurs sont supprimés puis recréés.

---

# ⚙️ Configuration

Les variables d'environnement utilisées par les différents services sont regroupées dans :

```text
srcs/.env
```

Elles permettent notamment de définir :

* le nom de domaine ;
* le nom de la base de données ;
* l'utilisateur MariaDB ;
* les mots de passe MariaDB ;
* les identifiants WordPress ;
* l'adresse du serveur MariaDB.

Le fichier Compose charge ce fichier avec :

```yaml
env_file: .env
```

pour les différents services.

## ⚠️ Sécurité

**Attention : le fichier `srcs/.env` actuellement présent dans le dépôt contient des mots de passe et des identifiants réels.**

Pour un dépôt public, il est fortement recommandé de :

1. ajouter `srcs/.env` au `.gitignore` ;
2. créer un fichier `srcs/.env.example` sans secrets ;
3. utiliser des mots de passe suffisamment robustes ;
4. remplacer les mots de passe actuellement exposés ;
5. si nécessaire, nettoyer également l'historique Git pour supprimer les secrets déjà commités.

**Les mots de passe présents dans le dépôt doivent être considérés comme compromis.**

---

# 🚀 Installation

## Prérequis

* Linux ;
* Docker ;
* Docker Compose (`docker compose`) ;
* `make` ;
* connexion Internet pour construire les images et télécharger WordPress.

## Cloner le projet

```bash
git clone git@github.com:SaifMgaidi/inception.git
cd inception
```

## Configurer le domaine

Le projet utilise :

```text
sm-gaidi.42.fr
```

Pour un environnement local, ajouter par exemple dans `/etc/hosts` :

```text
127.0.0.1 sm-gaidi.42.fr
```

## Configurer les variables d'environnement

Configurer :

```text
srcs/.env
```

avec les variables nécessaires au projet.

## Lancer l'infrastructure

Depuis la racine du dépôt :

```bash
make
```

Le `Makefile` :

1. crée les dossiers nécessaires aux volumes ;
2. construit les images ;
3. démarre les conteneurs en arrière-plan.

---

# 🔍 Vérification

## État des conteneurs

```bash
docker compose -f srcs/docker-compose.yml ps
```

## Logs

```bash
docker compose -f srcs/docker-compose.yml logs
```

Pour un service particulier :

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

## Accéder au site

Une fois l'infrastructure démarrée :

```text
https://sm-gaidi.42.fr
```

Comme le certificat est auto-signé, le navigateur peut afficher un avertissement de sécurité.

---

# 🛑 Arrêter le projet

```bash
make down
```

Cette commande arrête les conteneurs et supprime les ressources gérées par Docker Compose tout en conservant les données présentes dans les dossiers de volumes.

---

# 🧹 Nettoyage

## `make clean`

```bash
make clean
```

Cette commande commence par arrêter l'infrastructure puis exécute :

```bash
docker system prune -a --force
```

Elle permet de supprimer les ressources Docker inutilisées.

## `make fclean`

```bash
make fclean
```

Cette commande effectue un nettoyage plus important et supprime également les données présentes dans :

```text
/home/sm-gaidi/data/mariadb
/home/sm-gaidi/data/wordpress
```

⚠️ **Cette opération entraîne la suppression des données persistantes du projet.**

## `make re`

```bash
make re
```

Permet de repartir de zéro :

```text
fclean
  ↓
all
  ↓
reconstruction complète
```

---

# 🧰 Commandes Docker utiles

### Conteneurs actifs

```bash
docker ps
```

### Tous les conteneurs

```bash
docker ps -a
```

### Images

```bash
docker images
```

### Volumes

```bash
docker volume ls
```

### Réseaux

```bash
docker network ls
```

### Inspecter le réseau

```bash
docker network inspect inception_inception_network
```

### Entrer dans un conteneur

```bash
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
```

---

# 🔐 HTTPS

NGINX utilise un certificat auto-signé généré avec OpenSSL :

```text
/etc/nginx/ssl/inception.crt
/etc/nginx/ssl/inception.key
```

Le certificat est généré lors de la construction de l'image NGINX.

La configuration NGINX limite les protocoles à :

```text
TLSv1.2
TLSv1.3
```

---

# 🔄 Initialisation et redémarrage

Le projet distingue une première initialisation d'un environnement déjà configuré.

## Première exécution

MariaDB :

* initialise la base ;
* crée l'utilisateur ;
* configure les privilèges.

WordPress :

* télécharge les fichiers ;
* crée `wp-config.php` ;
* installe WordPress ;
* crée les utilisateurs.

## Exécutions suivantes

Les données étant conservées dans les volumes, les conteneurs peuvent être recréés sans perdre automatiquement les données.

Le script WordPress vérifie notamment l'existence de :

```text
wp-config.php
```

avant de procéder à une nouvelle installation.

MariaDB effectue de son côté une vérification du dossier de base de données avant son initialisation.

---

# 📚 Concepts étudiés

Ce projet permet de travailler concrètement sur :

* Docker ;
* Dockerfiles ;
* Docker Compose ;
* images Docker ;
* conteneurs ;
* isolation des services ;
* réseaux Docker ;
* volumes ;
* persistance des données ;
* variables d'environnement ;
* NGINX ;
* HTTPS ;
* SSL/TLS ;
* certificats auto-signés ;
* PHP-FPM ;
* FastCGI ;
* WordPress ;
* WP-CLI ;
* MariaDB ;
* SQL ;
* scripts Bash ;
* processus PID 1 ;
* initialisation de services ;
* communication inter-conteneurs.

---

# 👤 Auteur

**Saif Mgaidi**

Étudiant à **42 Paris**

GitHub : `SaifMgaidi`

Repository : `SaifMgaidi/inception`
