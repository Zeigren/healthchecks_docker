# Docker Stack For [Healthchecks](https://github.com/healthchecks/healthchecks)

![Docker Image Size (latest)](https://img.shields.io/docker/image-size/zeigren/healthchecks/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/healthchecks)

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy Healthchecks. Templates included for using NGINX or Traefik for SSL termination.

## Links

### [Docker Hub](https://hub.docker.com/r/zeigren/healthchecks)

### [GitHub](https://github.com/Zeigren/healthchecks-docker)

## Tags

- v1.20.0

## Stack

- [Python:Alpine](https://hub.docker.com/_/python) for Healthchecks
- [NGINX:Alpine](https://hub.docker.com/_/nginx)

## Configuration

Configuration consists of variables in the `.yml` and `.conf` files.

- healthchecks_vhost = A simple NGINX vhost file for Healthchecks (templates included, use `healthchecks_vhost_ssl` if you're using NGINX for SSL termination)
- Make whatever changes you need to the appropriate `.yml`. Environment variables for Healthchecks can be found in the `docker-entrypoint.sh` and the [healthchecks.io](https://healthchecks.io/docs/self_hosted_configuration/) website

### Using NGINX for SSL Termination

- yourdomain.test.crt = The SSL certificate for your domain (you'll need to create/copy this)
- yourdomain.test.key = The SSL key for your domain (you'll need to create/copy this)

## Deployment

On first run you'll need to create a superuser by attaching to the container and running `python manage.py createsuperuser`.

### [Docker Compose](https://docs.docker.com/compose/)

Create a `config` folder inside the `healthchecks-docker` directory, and put the relevant configuration files you created/modified into it.

Run with `docker-compose -f docker-compose.yml up -d`. View using `127.0.0.1:9080`.

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, I've included an example `traefik.yml` but it's not necessary.

You'll need to create the appropriate [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

Any environment variables for Healthchecks in `docker-entrypoint.sh` can instead be set using Docker Secrets, there's an example of how to do this in the relevant `.yml` files.

Run with `docker stack deploy --compose-file docker-swarm.yml healthchecks`

## Theory of operation

### Healthchecks

The [Dockerfile](https://docs.docker.com/engine/reference/builder/) uses [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/), [build hooks](https://docs.docker.com/docker-hub/builds/advanced/#build-hook-examples), and [labels](http://label-schema.org/rc1/#build-time-labels) for automated builds on Docker Hub.

The multi-stage build creates a build container that has all the dependencies for the python packages which are installed into a [python virtual environment](https://docs.python.org/3/tutorial/venv.html). The production container copies the python virtual environment from the build container and runs healthchecks from there, this allows it to be much more lightweight.

On startup, the container first runs the `docker-entrypoint.sh` script before running `gunicorn`.

`docker-entrypoint.sh` creates configuration files and runs commands based on environment variables that are declared in the various `.yml` files.

`env_secrets_expand.sh` handles using Docker Secrets.

### Nginx

Used as a web server. It serves up the static files and passes everything else off to gunicorn/healthchecks.
