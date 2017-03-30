#!/bin/bash

set -e

MAXDOMAIN=9


letsencrypt_configure() {
	local domain=$1
	local email=$2

	# start nginx
	/usr/sbin/nginx -g "daemon on;"

	# letsencrypt cert
	if /opt/letsencrypt/letsencrypt-auto certonly \
						--text \
						--no-self-upgrade \
						--agree-tos \
						--email ${email} \
						--rsa-key-size 4096 \
						--webroot \
						--webroot-path /etc/letsencrypt/www \
						--domain ${domain}
	then
		# Echo quickstart guide to logs
		echo
		echo '================================================================================='
		echo "Your ${domain} letsencrypt container is now ready to use!"
		echo '================================================================================='
		echo

		# Bunch the certs for the first time
		/usr/local/bin/bunch_certificate.sh "${domain}"
	else
		echo
		echo '================================================================================='
		echo "Your ${DOMAIN_ARRAY[$i]} letsencrypt container can't get certificates!"
		echo '================================================================================='
		echo
	fi

	# stop nginx
	/usr/sbin/nginx -s stop
}


# set EMAIL and DOMAIN arrays
for (( i=1; i<=${MAXDOMAIN}; i++ )); do
	if [[ -v EMAIL${i} && -v DOMAIN${i} ]]; then
		fullmai="EMAIL${i}"
		fulldom="DOMAIN${i}"
	 	EMAIL_ARRAY[${i}]=${!fullmai//[[:space:]]/}
	 	DOMAIN_ARRAY[${i}]=${!fulldom//[[:space:]]/}
	fi
done


# one email/domain at least must be defined
if [[ -z "${EMAIL_ARRAY[*]}" || -z "${DOMAIN_ARRAY[*]}" ]]; then
	echo >&2 'Notice: undefined variable(s) EMAIL1..9 or DOMAIN1..9! - skipping ...'
	exit 1
fi

[[ -d /etc/letsencrypt/www ]] || mkdir -p /etc/letsencrypt/www


case "$@" in
	bash|/bin/bash)
		/bin/bash
		;;
	configure)
		for (( i=1; i<=${#DOMAIN_ARRAY[@]}; i++ )); do
			# nginx config
			[[ -f /etc/nginx/conf.d/letsencrypt.conf ]] || sed -e "s/___HOSTNAME___/${HOSTNAME}/g" /etc/nginx/nginx-letsencrypt.conf >/etc/nginx/conf.d/letsencrypt.conf
			[[ -d "/etc/letsencrypt/live/${DOMAIN_ARRAY[$i]}" ]] || letsencrypt_configure "${DOMAIN_ARRAY[$i]}" "${EMAIL_ARRAY[$i]}"

			# configure cron
			[[ -f "/etc/cron.d/letsencrypt-renew" ]] && rm -f /etc/cron.d/letsencrypt-renew
			echo -e "10 1 * * 0 root /opt/letsencrypt/letsencrypt-auto renew --no-self-upgrade >>/var/log/letsencrypt_renew.log\n" >>/etc/cron.d/letsencrypt-renew

			[[ -f "/etc/cron.d/${DOMAIN_ARRAY[$i]//./-}" ]] && rm -f /etc/cron.d/${DOMAIN_ARRAY[$i]//./-}
			echo -e "4${i} 1 * * 0 root /usr/local/bin/bunch_certificate.sh \"${DOMAIN_ARRAY[$i]}\"\n" >>/etc/cron.d/${DOMAIN_ARRAY[$i]//./-}
		done
		exit 0
		;;
	*)
		/usr/bin/supervisord
		exit 0
		;;
esac
