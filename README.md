*This project has been created as part of the 42 curriculum by sm-gaidi.*

# Inception

## Description

Inception is a 42 project focused on building a small web infrastructure using Docker Compose.

The infrastructure is composed of three services, each running in its own Docker container:

- **NGINX**: the only public entry point. It handles HTTPS connections on port 443 and forwards PHP requests to WordPress through FastCGI.
- **WordPress + PHP-FPM**: provides the website and executes PHP code.
- **MariaDB**: stores the WordPress database.

The services communicate through a dedicated Docker bridge network. Persistent project data is stored in the host data directories required by the project.

## Architecture

```text
                         HTTPS :443
                              |
                              v
                    +------------------+
                    |      NGINX       |
                    |   SSL / HTTPS    |
                    +--------+---------+
                             |
                        FastCGI :9000
                             |
                             v
                    +------------------+
                    |    WORDPRESS     |
                    |    PHP-FPM       |
                    |      WP-CLI      |
                    +--------+---------+
                             |
                         MySQL :3306
                             |
                             v
                    +------------------+
                    |     MARIADB      |
                    +------------------+

                    Docker bridge network
                    inception_network
```

### Request flow

1. The browser connects to `sm-gaidi.42.fr` through HTTPS on port `443`.
2. NGINX receives the request and serves static files.
3. PHP requests are forwarded to PHP-FPM in the WordPress container through `wordpress:9000`.
4. WordPress connects to MariaDB through the Docker service name `mariadb`.
5. MariaDB and WordPress data are stored persistently in the project data directories.

## Project structure

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
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
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── wordpress.sh
```

> `srcs/.env` is a local configuration file and must not be committed to Git.

# Services

## MariaDB

The MariaDB container is built from `debian:bookworm` and installs the MariaDB server.

Its configuration:

- installs MariaDB;
- configures the database server;
- listens on port `3306`;
- accepts connections from the Docker network;
- uses `mariadb.sh` to initialize the database.

### Initialization

The `mariadb.sh` script:

1. starts MariaDB temporarily when initialization is required;
2. waits until the server is ready;
3. creates the database;
4. creates the WordPress database user;
5. grants the required privileges;
6. configures the root password;
7. shuts down the temporary server;
8. starts MariaDB in the foreground.

## WordPress

The WordPress container is built from `debian:bookworm`.

It installs:

- PHP-FPM;
- `php-mysql`;
- `mariadb-client`;
- `curl`;
- WP-CLI.

### Initialization

The `wordpress.sh` script:

1. waits for MariaDB to be available;
2. downloads WordPress during the first initialization;
3. creates `wp-config.php`;
4. configures the MariaDB connection;
5. installs WordPress;
6. creates the administrator account;
7. creates a second WordPress user;
8. prepares the PHP runtime directory;
9. gives the website files to `www-data`;
10. starts PHP-FPM in the foreground.

PHP-FPM runs as `www-data` instead of root.

## NGINX

The NGINX container is built from `debian:bookworm`.

It installs:

- NGINX;
- OpenSSL.

NGINX:

- listens on port `443`;
- uses HTTPS;
- supports TLS 1.2 and TLS 1.3;
- serves `/var/www/html`;
- forwards PHP requests to `wordpress:9000` through FastCGI.

A self-signed TLS certificate is generated during the NGINX image build.

# Docker network

The three services use the dedicated Docker network:

```text
inception_network
```

The network uses the Docker `bridge` driver.

Services communicate through Docker service names:

```text
nginx      -> wordpress:9000
wordpress  -> mariadb:3306
```

MariaDB and PHP-FPM are not directly exposed on the host.

Only HTTPS port `443` is published:

```yaml
ports:
  - "443:443"
```

# Volumes and data persistence

The project uses two persistent volumes:

```text
MariaDB:
    /home/sm-gaidi/data/mariadb
        |
        v
    /var/lib/mysql

WordPress:
    /home/sm-gaidi/data/wordpress
        |
        v
    /var/www/html
```

The MariaDB volume stores database files.

The WordPress volume stores the WordPress installation and website files, including `wp-config.php`.

The data remains available when containers are recreated.

# Configuration and credentials

The project configuration is stored locally in:

```text
srcs/.env
```

The file contains environment variables used by the different services, including database and WordPress configuration.

The Compose file loads these variables with:

```yaml
env_file: .env
```

The `.env` file contains sensitive information and is ignored by Git. It must never be committed or shared publicly.

# Installation

## Prerequisites

- Linux
- Docker
- Docker Compose (`docker compose`)
- `make`
- Internet access to build the images and download WordPress

## Clone the repository

```bash
git clone git@github.com:SaifMgaidi/inception.git
cd inception
```

## Configure the environment

Create the local environment file:

```text
srcs/.env
```

and configure the variables required by the project.

Do not commit this file.

## Configure the domain

The project uses:

```text
sm-gaidi.42.fr
```

For a local environment, the domain can be mapped to the local machine in `/etc/hosts`:

```text
127.0.0.1 sm-gaidi.42.fr
```

## Start the infrastructure

From the project root:

```bash
make
```

The Makefile creates the required data directories, builds the Docker images and starts the containers.

# Instructions

## Stop the project

```bash
make down
```

This stops the project containers.

## Check the containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

The expected services are:

- `mariadb`
- `wordpress`
- `nginx`

## Check the logs

```bash
docker compose -f srcs/docker-compose.yml logs
```

For a specific service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

## Access WordPress

Once the infrastructure is running:

```text
https://sm-gaidi.42.fr
```

The administration panel is available at:

```text
https://sm-gaidi.42.fr/wp-admin
```

The browser may display a warning because the project uses a self-signed certificate.

## Clean the project

```bash
make clean
```

```bash
make fclean
```

> `make fclean` also removes the persistent project data stored in `/home/sm-gaidi/data/`.

To rebuild the project from scratch:

```bash
make re
```

# Required comparisons

## Virtual Machines vs Docker

A virtual machine emulates or virtualizes an entire operating system. Each VM has its own operating system, kernel and allocated resources.

Docker containers share the host kernel and isolate applications and their dependencies. They are generally lighter and faster to start than virtual machines.

For this project, Docker is appropriate because each service can be isolated in its own container while communicating through a dedicated Docker network.

## Secrets vs Environment Variables

Environment variables are convenient for passing configuration values to containers, but sensitive values stored directly in environment variables can be exposed through configuration or process inspection.

Docker secrets provide a mechanism designed to handle sensitive values more securely by making secret data available to a container as files.

For a production infrastructure, secrets are preferable for sensitive credentials. In this project, environment variables are used because they are part of the project configuration and are stored locally in `.env`.

## Docker Network vs Host Network

A Docker bridge network provides an isolated virtual network between containers. Containers can communicate using Docker service names without exposing every service to the host.

Host networking removes most of this network isolation and makes the container use the host network namespace directly.

The project uses a dedicated bridge network so that NGINX, WordPress and MariaDB can communicate internally while only HTTPS port `443` is exposed to the host.

## Docker Volumes vs Bind Mounts

Docker volumes are managed by Docker and are commonly used to persist container data.

Bind mounts directly map a specific host path into a container.

This project uses the host paths required by the Inception subject for persistent data and configures them through Docker's volume mechanism.

# HTTPS

NGINX uses a self-signed certificate generated with OpenSSL.

The certificate and private key are stored inside the NGINX image at:

```text
/etc/nginx/ssl/inception.crt
/etc/nginx/ssl/inception.key
```

TLS is restricted to:

```text
TLSv1.2
TLSv1.3
```

# Persistence and initialization

On the first initialization:

- MariaDB creates the required database and user.
- WordPress downloads and installs WordPress.
- WordPress creates the configured users.

On subsequent container starts, the existing persistent data is reused.

The WordPress initialization script checks for `wp-config.php` before installing WordPress again.

# Resources

## Docker

- Docker documentation
- Docker Compose documentation
- Dockerfile reference

## WordPress

- WordPress documentation
- WP-CLI documentation

## NGINX

- NGINX documentation
- OpenSSL documentation

## MariaDB

- MariaDB documentation

## 42

- 42 Inception subject

## AI usage

AI tools were used as learning and assistance tools during the development of this project.

AI-generated suggestions were reviewed, understood and adapted before being used. Commands and configuration changes were tested in the project environment.

The final implementation remains the responsibility of the author, who must be able to explain and justify the code and configuration used in this project.

# Author

**Saif Mgaidi**

42 Paris

GitHub: `SaifMgaidi`

Repository: `SaifMgaidi/inception`
