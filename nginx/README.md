# Configuration

Configuration consists of variables in the `.yml` and `.conf` files.

- healthchecks_nginx.conf = NGINX config file (only needs to be modified if you're using NGINX for SSL termination)
- Make whatever changes you need to the appropriate `.yml`. Environment variables for Healthchecks can be found in the `docker-entrypoint.sh` and the [healthchecks.io](https://healthchecks.io/docs/self_hosted_configuration/) website

## Using NGINX for SSL Termination

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
