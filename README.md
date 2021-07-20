# Docker Stack For [Healthchecks](https://github.com/healthchecks/healthchecks)

![Docker Image Size (latest)](https://img.shields.io/docker/image-size/zeigren/healthchecks/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/healthchecks)

## Links

### [Docker Hub](https://hub.docker.com/r/zeigren/healthchecks)

### [ghcr.io](https://ghcr.io/zeigren/healthchecks_docker)

### [GitHub](https://github.com/Zeigren/healthchecks_docker)

## Tags

- latest
- v1.21.0
- v1.20.0

## Stack

- Python:Alpine - Healthchecks
- Caddy or NGINX - web server

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy. Containers are available from both Docker Hub and the GitHub Container Registry.

There are examples for using either [Caddy](https://caddyserver.com/) or [NGINX](https://www.nginx.com/) as the web server and examples for using Caddy, NGINX, or [Traefik](https://traefik.io/traefik/) for HTTPS (the Traefik example also includes using it as a reverse proxy). The NGINX examples are in the nginx folder.

## Recommendations

I recommend using Caddy as the web server and either have it handle HTTPS or pair it with Traefik as they both have native [ACME](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment) support for automatically getting HTTPS certificates from [Let's Encrypt](https://letsencrypt.org/) or will create self signed certificates for local use.

If you can I also recommend using [Docker Swarm](https://docs.docker.com/engine/swarm/) over [Docker Compose](https://docs.docker.com/compose/) as it supports [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

If Caddy doesn't work for you or you are chasing performance then checkout the NGINX examples. I haven't done any performance testing but NGINX has a lot of configurability which may let you squeeze out better performance if you have a lot of users, also check the performance section below.

## Configuration

Configuration consists of setting environment variables in the `.yml` files. More environment variables for configuring [healthchecks](https://healthchecks.io/docs/self_hosted_configuration/) can be found in `docker-entrypoint.sh` and for Caddy in `bookstack_caddyfile`.

Setting the `DOMAIN` variable changes whether Caddy uses HTTP, HTTPS with a self signed certificate, or HTTPS with a certificate from Let's Encrypt or ZeroSSL. Check the Caddy [documentation](https://caddyserver.com/docs/automatic-https) for more info.

On first run you'll need to create a superuser by attaching to the container and running `python manage.py createsuperuser`.

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, I've included an example `traefik.yml` but it's not necessary.

You'll need to create the appropriate [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

Any environment variables for Healthchecks in `docker-entrypoint.sh` can instead be set using Docker Secrets, there's an example of how to do this in the relevant `.yml` files.

Run with `docker stack deploy --compose-file docker-swarm.yml healthchecks`

### [Docker Compose](https://docs.docker.com/compose/)

Run with `docker-compose -f docker-compose.yml up -d`. View using `127.0.0.1:9080`.

### Performance Tuning

The web servers set the relevant HTTP headers to have browsers cache as much as they can for as long as they can while requiring browsers to check if those files have changed, this is to get the benefit of caching without having to deal with the caches potentially serving old content. If content doesn't change that often or can be invalidated in another way then this behavior can be changed to reduce the number of requests.

The number of [workers](https://docs.gunicorn.org/en/stable/settings.html#workers) Gunicorn uses can be set with the `GUNICORN_WORKERS` environment variable.

## Theory of operation

The [Dockerfile](https://docs.docker.com/engine/reference/builder/) uses [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/), [build hooks](https://docs.docker.com/docker-hub/builds/advanced/#build-hook-examples), and [labels](http://label-schema.org/rc1/#build-time-labels) for automated builds on Docker Hub.

The multi-stage build creates a build container that has all the dependencies for the python packages which are installed into a [python virtual environment](https://docs.python.org/3/tutorial/venv.html). The production container copies the python virtual environment from the build container and runs healthchecks from there, this allows it to be much more lightweight.

On startup, the container first runs the `docker-entrypoint.sh` script before running `gunicorn`.

`docker-entrypoint.sh` creates configuration files and runs commands based on environment variables that are declared in the various `.yml` files.

`env_secrets_expand.sh` handles using Docker Secrets.
