# letsencrypt

Docker image with letsencrypt + nginx

This image can manage up to 9 domains.
It uses nginx during the configuration step.
Otherwise, it launch the cron daemon to renew certs when needed.

Before managing container (e.g. within docker-compose), the container must be launch once with nginx visible on the Internet to perform domain validation :

  * Create named volume which is going to include certificates

	`docker create volume --name letsencrypt_certificates`

  * Run a temp letsencrypt container to create and validate certificates for the first time (nginx use)

    `docker run --rm -v letsencrypt_certificates:/etc/letsencrypt -p 80:80 -e DOMAIN1=xxxx -e EMAIL1=xxxx -e DOMAIN2=xxxx -e EMAIL2=xxxx flem/letsencrypt-nginx configure`

Then you can start container and links it with HAProxy, Nginx, Apache ...

`docker run -d --name letsencrypt_container -v letsencrypt_certificates:/etc/letsencrypt -e DOMAIN1=xxxx -e EMAIL1=xxxx -e DOMAIN2=xxxx -e EMAIL2=xxxx flem/letsencrypt-nginx`
