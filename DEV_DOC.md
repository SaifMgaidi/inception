# Developer Documentation

## 1. Project Overview

This project is part of the **42 Inception** system administration project.

The goal is to build a small web infrastructure using Docker Compose, with each service running inside its own dedicated container.

The current infrastructure contains three services:

* **NGINX**: HTTPS web server and only external entry point.
* **WordPress + PHP-FPM**: web application and PHP execution environment.
* **MariaDB**: relational database used by WordPress.

The project is built from custom Dockerfiles based on Debian.

According to the project requirements, each service must have its own container and its own Dockerfile, and the containers must communicate through a Docker network.

---

# 2. Project Structure

The current repository is organized as follows:

```text
inception/
├── Makefile
├── README.md
├── DEV_DOC.md
├── srcs/
│   ├── .env
│   ├── docker-compose.yml
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   ├── conf/
│       │   │   └── 50-server.cnf
│       │   └── tools/
│       │       └── mariadb.sh
│       │
│       ├── nginx/
│       │   ├── Dockerfile
│       │   └── conf/
│       │       └── nginx.conf
│       │
│       └── wordpress/
│           ├── Dockerfile
│           ├── conf/
│           │   └── www.conf
│           └── tools/
│               └── wordpress.sh
```

The subject requires configuration files to be placed inside `srcs`, with the `Makefile` at the repository root.

---

# 3. Prerequisites

Before building the project, the development environment must provide:

* A Linux virtual machine.
* Docker.
* Docker Compose.
* GNU Make.
* Internet access.

The Inception project must be performed inside a virtual machine and Docker Compose must be used.
The Docker images are built from Debian. The subject requires using either the penultimate stable version of Debian or Alpine.

The current project uses:

```dockerfile
FROM debian:bookworm
```

for MariaDB, WordPress and NGINX.

---

# 4. Domain Configuration

The project uses the domain:

```text
sm-gaidi.42.fr
```

The subject requires the domain to follow the format:

```text
login.42.fr
```

where `login` is the student's 42 login.

For local development, the domain must point to the IP address of the virtual machine.

For example, `/etc/hosts` can contain:

```text
127.0.0.1 sm-gaidi.42.fr
```

If the VM uses another IP address, the corresponding VM IP must be used instead.

---

# 5. Environment Variables

The project uses an environment file:

```text
srcs/.env
```

The Docker Compose file loads this file for the services using:

```yaml
env_file: .env
```

The current configuration contains variables for:

```text
DOMAIN_NAME
SQL_DATABASE
SQL_USER
SQL_PASSWORD
SQL_ROOT_PASSWORD
WORDPRESS_DB_HOST

WP_ADMIN_USER
WP_ADMIN_PASSWORD
WP_ADMIN_EMAIL

WP_USER
WP_PASSWORD
WP_EMAIL
```

These variables are used by the MariaDB and WordPress initialization scripts.

For example:

```text
WORDPRESS_DB_HOST=mariadb
```

allows WordPress to reach MariaDB through the Docker network using the service name.

The subject requires environment variables and a `.env` file. It also strongly recommends using Docker secrets for confidential information.

## Security requirement

Passwords must **not** be stored directly inside Dockerfiles.

The subject explicitly states that credentials, passwords and API keys found in the Git repository outside properly configured secrets can result in project failure.

Therefore, before final submission, credentials should be removed from the public Git repository and replaced by appropriate local configuration/secrets.

---

# 6. Docker Compose

The main Compose configuration is:

```text
srcs/docker-compose.yml
```

It defines three services:

```yaml
services:
  mariadb:
  wordpress:
  nginx:
```

The three services are connected to:

```text
inception_network
```

using a Docker bridge network.

The Compose configuration also uses:

```yaml
restart: always
```

for every service.

This ensures Docker attempts to restart the containers if they stop unexpectedly.

The subject requires containers to restart in case of a crash.

---

# 7. Service Dependencies

The current Compose configuration declares:

```yaml
wordpress:
  depends_on:
    - mariadb

nginx:
  depends_on:
    - wordpress
```

This defines the startup dependency order:

```text
MariaDB
   ↓
WordPress
   ↓
NGINX
```

However, `depends_on` alone does not guarantee that a service is ready to accept connections.

For this reason, the WordPress startup script contains its own MariaDB readiness check.

---

# 8. MariaDB

## 8.1 Dockerfile

The MariaDB image is built from:

```dockerfile
FROM debian:bookworm
```

The Dockerfile installs MariaDB:

```dockerfile
RUN apt-get update -y && apt-get install mariadb-server -y
```

It then copies the MariaDB configuration:

```text
conf/50-server.cnf
```

to:

```text
/etc/mysql/mariadb.conf.d/50-server.cnf
```

The bind address is configured to allow MariaDB to accept connections from the Docker network:

```text
bind-address = 0.0.0.0
```

The project then installs:

```text
tools/mariadb.sh
```

as the container entrypoint.

---

# 9. MariaDB Initialization

The entrypoint is:

```text
srcs/requirements/mariadb/tools/mariadb.sh
```

The script first enables:

```bash
set -e
```

so that the script stops if a command fails.

It checks whether the database directory already exists:

```bash
if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
```

If the database has not yet been initialized, MariaDB is temporarily started:

```bash
service mariadb start
```

The script then waits for MariaDB to become ready:

```bash
while ! mysqladmin ping --silent; do
    sleep 1
done
```

Once MariaDB is ready, the script:

1. Creates the WordPress database.
2. Creates the WordPress user.
3. Grants privileges on the WordPress database.
4. Sets the root password.
5. Flushes privileges.
6. Shuts down the temporary MariaDB instance.

Finally:

```bash
exec mysqld_safe
```

starts MariaDB as the main process of the container.

The use of `exec` is important because the final MariaDB process becomes the main process of the container instead of leaving the shell script as the main process.

---

# 10. WordPress

## 10.1 Dockerfile

The WordPress image is based on:

```dockerfile
FROM debian:bookworm
```

The following packages are installed:

```text
php-fpm
php-mysql
curl
mariadb-client
```

WP-CLI is downloaded and installed as:

```text
/usr/local/bin/wp
```

The Dockerfile also creates:

```text
/var/www/html
```

and copies the PHP-FPM configuration:

```text
conf/www.conf
```

to:

```text
/etc/php/8.2/fpm/pool.d/www.conf
```

The initialization script is copied to:

```text
/usr/local/bin/wordpress.sh
```

and used as the container entrypoint.

---

# 11. PHP-FPM Configuration

The PHP-FPM configuration uses the `www` pool:

```ini
[www]
```

PHP-FPM runs using:

```ini
user = www-data
group = www-data
```

This prevents PHP-FPM from running its workers as root.

PHP-FPM listens on:

```ini
listen = 9000
```

This port is used for communication with NGINX through FastCGI.

The process manager is configured as:

```ini
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

Environment variables are preserved with:

```ini
clear_env = no
```

This is necessary in the current architecture because WordPress initialization uses environment variables provided by Docker Compose.

---

# 12. WordPress Initialization

The WordPress entrypoint is:

```text
srcs/requirements/wordpress/tools/wordpress.sh
```

The script first waits for MariaDB:

```bash
while ! mysqladmin ping \
    -h"${WORDPRESS_DB_HOST}" \
    -u"${SQL_USER}" \
    -p"${SQL_PASSWORD}" \
    --silent; do
    sleep 1
done
```

This is important because Docker's `depends_on` only controls startup order and does not guarantee database readiness.

Once MariaDB is available, the script checks:

```bash
if [ ! -f wp-config.php ]; then
```

If WordPress has not yet been configured, the script:

### 1. Downloads WordPress

```bash
wp core download --allow-root --force
```

### 2. Creates `wp-config.php`

```bash
wp config create
```

The database configuration uses:

```text
SQL_DATABASE
SQL_USER
SQL_PASSWORD
WORDPRESS_DB_HOST
```

### 3. Installs WordPress

```bash
wp core install
```

The domain and administrator credentials are supplied through environment variables.

### 4. Creates a second user

The script creates a second WordPress user with the:

```text
author
```

role.

The subject requires two WordPress users, including an administrator. The administrator username must not contain `admin` or `administrator`.

### 5. Starts PHP-FPM

The script creates:

```text
/run/php
```

and changes ownership of the WordPress directory:

```bash
chown -R www-data:www-data /var/www/html
```

Finally:

```bash
exec php-fpm8.2 -F
```

starts PHP-FPM in the foreground.

---

# 13. NGINX

## 13.1 Dockerfile

The NGINX image is based on:

```dockerfile
FROM debian:bookworm
```

The Dockerfile installs:

```text
nginx
openssl
```

It creates:

```text
/etc/nginx/ssl
```

and generates a self-signed certificate:

```text
/etc/nginx/ssl/inception.crt
/etc/nginx/ssl/inception.key
```

The NGINX configuration is copied to:

```text
/etc/nginx/sites-available/default
```

The image exposes:

```text
443
```

and launches NGINX in the foreground:

```dockerfile
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

---

# 14. NGINX Configuration

NGINX listens on:

```text
443
```

for both IPv4 and IPv6.

The configured domain is:

```text
sm-gaidi.42.fr
```

The SSL certificate is configured using:

```nginx
ssl_certificate /etc/nginx/ssl/inception.crt;
ssl_certificate_key /etc/nginx/ssl/inception.key;
```

Only the following TLS versions are enabled:

```text
TLSv1.2
TLSv1.3
```

The subject requires NGINX to use TLSv1.2 or TLSv1.3 only.

PHP requests are forwarded to:

```text
wordpress:9000
```

using FastCGI:

```nginx
fastcgi_pass wordpress:9000;
```

---

# 15. Container Communication

The architecture uses Docker's internal DNS.

The WordPress container does not connect to a hard-coded IP address.

Instead, it connects to:

```text
mariadb
```

which is the MariaDB service name.

NGINX connects to PHP-FPM through:

```text
wordpress:9000
```

The resulting communication is:

```text
Browser
   │
   │ HTTPS :443
   ▼
 NGINX
   │
   │ FastCGI :9000
   ▼
WordPress / PHP-FPM
   │
   │ MySQL
   ▼
 MariaDB
```

The project uses a dedicated Docker bridge network:

```text
inception_network
```

The subject requires a Docker network connecting the containers and explicitly forbids host networking and Docker links.

---

# 16. Volumes and Data Persistence

The project needs two persistent storage areas:

1. WordPress database.
2. WordPress website files.

The current Compose configuration declares:

```yaml
mariadb_vol:
wordpress_vol:
```

MariaDB uses:

```text
/var/lib/mysql
```

inside the container.

WordPress uses:

```text
/var/www/html
```

inside the container.

The current host paths are:

```text
/home/sm-gaidi/data/mariadb
/home/sm-gaidi/data/wordpress
```

as configured in `docker-compose.yml`.

The subject requires the two persistent storages to be Docker named volumes and requires their data to be stored under:

```text
/home/login/data
```

on the host. It explicitly states that bind mounts are not allowed for these volumes.

### Important implementation note

The current Compose configuration uses:

```yaml
driver: local
driver_opts:
  type: none
  o: bind
  device: /home/sm-gaidi/data/...
```

This is technically a named Docker volume configured to use a host bind underneath, but it is still a **bind-based volume implementation**.

Therefore, this part should be reviewed before final evaluation because the subject explicitly says:

```text
Bind mounts are not allowed for these volumes.
```

---

# 17. Makefile

The Makefile is located at the repository root as required.

The main variable is:

```make
COMPOSE_FILE = srcs/docker-compose.yml
```

The available targets are:

```text
make
make all
make down
make clean
make fclean
make re
```

---

## 17.1 `make`

The default target is:

```make
all
```

It creates:

```text
/home/sm-gaidi/data/mariadb
/home/sm-gaidi/data/wordpress
```

and launches:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

This builds the three custom images and starts the containers in detached mode.

---

## 17.2 `make down`

```bash
make down
```

runs:

```bash
docker compose -f srcs/docker-compose.yml down
```

This stops and removes the Compose containers and network while keeping persistent host data.

---

## 17.3 `make clean`

```bash
make clean
```

first executes:

```text
make down
```

and then:

```bash
docker system prune -a --force
```

This removes unused Docker resources.

---

## 17.4 `make fclean`

```bash
make fclean
```

performs a more destructive cleanup.

It removes the data contained in:

```text
/home/sm-gaidi/data/mariadb/*
/home/sm-gaidi/data/wordpress/*
```

and removes Docker volumes.

This means that the persistent WordPress and MariaDB data can be lost.

**Do not run `make fclean` if you need to preserve the current database or website.**

---

## 17.5 `make re`

```bash
make re
```

is equivalent to:

```text
make fclean
make all
```

It completely cleans the existing installation and rebuilds the infrastructure from scratch.

---

# 18. Useful Docker Commands

## List running containers

```bash
docker ps
```

## List all containers

```bash
docker ps -a
```

## List images

```bash
docker images
```

## List volumes

```bash
docker volume ls
```

## List networks

```bash
docker network ls
```

## Inspect the network

```bash
docker network inspect inception_inception_network
```

## Display Compose status

```bash
docker compose -f srcs/docker-compose.yml ps
```

## Display all logs

```bash
docker compose -f srcs/docker-compose.yml logs
```

## Follow logs

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

## Display logs for one service

```bash
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

---

# 19. Entering Containers

For debugging purposes, a shell can be opened inside a running container.

### MariaDB

```bash
docker exec -it mariadb bash
```

### WordPress

```bash
docker exec -it wordpress bash
```

### NGINX

```bash
docker exec -it nginx bash
```

These commands are useful for checking configuration files, processes, permissions and network connectivity.

---

# 20. Checking Processes

A container should normally have its main service running as PID 1.

For example:

```bash
docker exec wordpress ps aux
```

and:

```bash
docker exec mariadb ps aux
```

The project deliberately starts the main services in the foreground.

For example, PHP-FPM is launched with:

```bash
php-fpm8.2 -F
```

and NGINX with:

```bash
nginx -g "daemon off;"
```

This follows the Docker principle that the main service should remain attached to the container's main process rather than using artificial infinite loops.

The subject explicitly prohibits commands such as:

```text
tail -f
sleep infinity
while true
```

as container-running mechanisms.

---

# 21. Checking MariaDB Connectivity

Inside the WordPress container:

```bash
mysqladmin ping \
    -h"${WORDPRESS_DB_HOST}" \
    -u"${SQL_USER}" \
    -p"${SQL_PASSWORD}"
```

A successful response confirms that the WordPress container can reach MariaDB through the Docker network.

Inside MariaDB, databases can be inspected with:

```bash
mysql -u root -p
```

and:

```sql
SHOW DATABASES;
```

Users can be inspected with:

```sql
SELECT User, Host FROM mysql.user;
```

---

# 22. Checking WordPress

Inside the WordPress container:

```bash
cd /var/www/html
```

Check the WordPress configuration:

```bash
ls -la
```

The presence of:

```text
wp-config.php
```

indicates that WordPress has already been configured.

WP-CLI can be used to inspect the installation:

```bash
wp core version --allow-root
```

Users can be listed with:

```bash
wp user list --allow-root
```

---

# 23. Checking PHP-FPM

Inside the WordPress container:

```bash
ps aux | grep php-fpm
```

PHP-FPM should be running in the foreground as the main container process.

The PHP-FPM configuration is located at:

```text
/etc/php/8.2/fpm/pool.d/www.conf
```

The configured listening port is:

```text
9000
```

---

# 24. Checking NGINX

Inside the NGINX container:

```bash
nginx -t
```

This verifies the NGINX configuration syntax.

The active configuration is:

```text
/etc/nginx/sites-available/default
```

The SSL files are:

```text
/etc/nginx/ssl/inception.crt
/etc/nginx/ssl/inception.key
```

The container exposes:

```text
443
```

and Docker publishes:

```text
443:443
```

to the host.

---

# 25. Rebuilding One Service

To rebuild the entire infrastructure:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

To rebuild only one service:

```bash
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml build nginx
```

Then recreate the service if necessary:

```bash
docker compose -f srcs/docker-compose.yml up -d mariadb
```

---

# 26. Full Clean Rebuild

For a completely fresh installation:

```bash
make re
```

This removes the existing data and Docker resources before rebuilding.

The sequence is:

```text
make re
   │
   ├── make fclean
   │      ├── make clean
   │      ├── make down
   │      ├── docker system prune
   │      ├── remove MariaDB data
   │      ├── remove WordPress data
   │      └── remove Docker volumes
   │
   └── make all
          ├── create data directories
          └── docker compose up -d --build
```

This is useful for testing the complete first-installation process.

---

# 27. Development Workflow

A typical development workflow is:

```text
1. Modify configuration / Dockerfile / script
             ↓
2. Build the affected image
             ↓
3. Recreate the service
             ↓
4. Check container status
             ↓
5. Inspect logs
             ↓
6. Test communication between services
             ↓
7. Test the website through HTTPS
```

Useful commands:

```bash
docker compose -f srcs/docker-compose.yml build
docker compose -f srcs/docker-compose.yml up -d
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f
```

---

# 28. Persistence Test

To verify that the infrastructure correctly persists data:

### Step 1 — Start the infrastructure

```bash
make
```

### Step 2 — Create or modify data

For example, modify the WordPress website or create a WordPress post.

### Step 3 — Stop the containers

```bash
make down
```

### Step 4 — Start them again

```bash
make
```

### Step 5 — Verify the data

The website and database should still contain their previous data as long as the persistent storage has not been deleted.

Do not use:

```bash
make fclean
```

during this test because it deletes the persistent data configured by the current Makefile.

---

# 29. Important Inception Requirements

During development and evaluation, the following requirements must be checked carefully.

## Dedicated containers

There must be one dedicated container for:

```text
NGINX
WordPress + PHP-FPM
MariaDB
```

The subject explicitly requires each service to run in its own container.

## NGINX as the only external entry point

Only NGINX should be exposed to the outside world through:

```text
443
```

The subject requires NGINX to be the only entry point through port 443 using TLSv1.2 or TLSv1.3.

## No host networking

The project must not use:

```text
network: host
```

or Docker links.

## No infinite-loop container workaround

The following approaches are prohibited:

```text
tail -f
sleep infinity
while true
```

The actual service must run as the container's main process.

## No ready-made service images

The project requires custom Dockerfiles and prohibits pulling ready-made service images. Alpine and Debian are exceptions because they are explicitly allowed as base images.

---

# 30. Current Architecture Summary

```text
                         Host machine
                              │
                         Port 443
                              │
                              ▼
                    ┌─────────────────┐
                    │      NGINX      │
                    │     HTTPS       │
                    │    TLS 1.2/1.3  │
                    └────────┬────────┘
                             │
                       FastCGI :9000
                             │
                             ▼
                    ┌─────────────────┐
                    │    WORDPRESS    │
                    │    PHP-FPM      │
                    │     WP-CLI      │
                    └────────┬────────┘
                             │
                         MySQL
                             │
                             ▼
                    ┌─────────────────┐
                    │     MARIADB     │
                    └─────────────────┘

              Docker bridge network:
                inception_network

Persistent storage:

/home/sm-gaidi/data/wordpress
              ↕
       /var/www/html

/home/sm-gaidi/data/mariadb
              ↕
        /var/lib/mysql
```

---

# 31. Files to Know for the Defense

A developer should be able to explain the role of each of these files.

| File                           | Purpose                                             |
| ------------------------------ | --------------------------------------------------- |
| `Makefile`                     | Builds, starts, stops and cleans the infrastructure |
| `srcs/docker-compose.yml`      | Defines services, network, volumes and dependencies |
| `srcs/.env`                    | Provides environment variables                      |
| `mariadb/Dockerfile`           | Builds the MariaDB image                            |
| `mariadb/conf/50-server.cnf`   | MariaDB configuration                               |
| `mariadb/tools/mariadb.sh`     | MariaDB initialization and startup                  |
| `wordpress/Dockerfile`         | Builds the WordPress/PHP-FPM image                  |
| `wordpress/conf/www.conf`      | PHP-FPM pool configuration                          |
| `wordpress/tools/wordpress.sh` | WordPress initialization and PHP-FPM startup        |
| `nginx/Dockerfile`             | Builds the NGINX image and SSL certificate          |
| `nginx/conf/nginx.conf`        | NGINX HTTPS and FastCGI configuration               |

---

# 32. Recommended Validation Checklist

Before evaluation, verify:

```text
[ ] The project runs inside the required VM environment.
[ ] Docker Compose starts all services.
[ ] Each service has its own container.
[ ] Each service has its own Dockerfile.
[ ] NGINX is the only external entry point.
[ ] Only port 443 is exposed.
[ ] TLS 1.2 / TLS 1.3 is configured.
[ ] WordPress uses PHP-FPM.
[ ] NGINX forwards PHP requests to WordPress.
[ ] WordPress can connect to MariaDB.
[ ] MariaDB contains the WordPress database.
[ ] Two WordPress users exist.
[ ] One user is an administrator.
[ ] The administrator username does not contain "admin".
[ ] Containers restart after a crash.
[ ] No host networking is used.
[ ] No Docker links are used.
[ ] No infinite-loop container workaround is used.
[ ] No passwords are present in Dockerfiles.
[ ] Credentials are not committed publicly.
[ ] Persistent storage survives container recreation.
[ ] The domain is configured as login.42.fr.
[ ] The required documentation files are present.
```

The requirements concerning containers, TLS, users, networking, credentials, environment variables and persistence are defined in the mandatory section of the subject.

---

# 33. Important Points to Review Before Submission

The current implementation should be reviewed against the subject in particular on the following points:

### 1. Persistent volumes

The current Compose configuration uses Docker volumes configured with:

```yaml
driver_opts:
  type: none
  o: bind
```

The subject explicitly prohibits bind mounts for the two persistent volumes.

### 2. Credentials

The `.env` file currently contains passwords and credentials.

The subject states that credentials stored in the Git repository can result in failure.

### 3. Documentation

The required documentation files must exist at the root:

```text
README.md
USER_DOC.md
DEV_DOC.md
```

and `DEV_DOC.md` must document environment setup, configuration/secrets, build/launch, Docker management commands and data persistence.

These points should be checked before considering the project ready for evaluation.

---

# 34. Conclusion

The infrastructure is built around three independent Docker services:

```text
NGINX
  ↓
WordPress / PHP-FPM
  ↓
MariaDB
```

Docker Compose provides:

* service orchestration;
* networking;
* persistent storage;
* restart policies;
* environment variable injection.

Each container has a specific responsibility, while the Docker network allows the services to communicate without exposing internal services directly to the host.

The main development principle is to keep the containers focused on their respective services and let Docker manage the infrastructure rather than trying to reproduce a complete virtual machine inside each container.
