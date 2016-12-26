# DESCRIPTION: letsencrypt within a container
# BUILD:       docker build -t flem/letsencrypt .
# RUN:         docker run -d \
#                         -e EMAIL1=user@domain.tld
#                         -e DOMAIN1=www.domain.tld
#                         flem/letsencrypt-nginx


FROM nginx:latest
MAINTAINER Franck Lemoine <franck.lemoine@flem.fr>

# properly setup debian sources
ENV DEBIAN_FRONTEND=noninteractive

RUN buildDeps=' \
		git \
		ca-certificates \
		cron \
	' \
	set -x \
	&& apt-get -y update \
	&& apt-get -y upgrade \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& update-ca-certificates \
	&& git config --global http.sslVerify false \
	&& git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt \
	&& /opt/letsencrypt/letsencrypt-auto --os-packages-only \
	&& sed -i "s/^user\s\+.\+;$/user www-data;/" /etc/nginx/nginx.conf \
    && rm -f /etc/nginx/conf.d/* \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/*

COPY nginx-letsencrypt.conf /etc/nginx/
COPY bunch_certificate.sh /usr/local/bin
COPY docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh \
	&& chmod +x /usr/local/bin/bunch_certificate.sh

VOLUME ["/etc/letsencrypt", "/var/www"]

ENTRYPOINT ["/docker-entrypoint.sh"]
