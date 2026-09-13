# User Documentation

## Services

This project provides three services:

- **NGINX**: acts as the only entry point to the infrastructure. It handles HTTPS connections on port 443 and forwards PHP requests to WordPress.
- **WordPress + PHP-FPM**: provides the website and executes PHP code.
- **MariaDB**: stores the WordPress database.

The three services run in separate Docker containers and communicate through a dedicated Docker network.

## Starting and stopping the project

To start the project, run the following command from the root of the repository:

```bash
make
```

This creates the required data directories, builds the Docker images and starts the containers.

To stop the project:

```bash
make down
```

To completely clean the project:

```bash
make fclean
```

> `make fclean` removes the project data stored in `/home/sm-gaidi/data/`.

## Accessing WordPress

Once the containers are running, the WordPress website can be accessed through:

```text
https://sm-gaidi.42.fr
```

The WordPress administration panel is available at:

```text
https://sm-gaidi.42.fr/wp-admin
```

The browser may display a warning because the project uses a self-signed TLS certificate. This is expected for this project.

## Managing credentials

The credentials required by the project are stored locally and must not be committed to Git.

The environment variables are stored in:

```text
srcs/.env
```

The `.env` file contains the database and WordPress configuration values used by the containers.

For security reasons, do not share or commit this file to the repository.

The WordPress administrator credentials are defined by the WordPress environment variables and are used to access the `/wp-admin` administration panel.

## Checking the services

To check that all containers are running correctly, use:

```bash
docker compose -f srcs/docker-compose.yml ps
```

The three containers should be running:

- `mariadb`
- `wordpress`
- `nginx`

To check the logs of a specific service:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

If a container is not running correctly, the logs can be used to identify the problem.
