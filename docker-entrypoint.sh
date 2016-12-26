#!/bin/bash

set -e

MAXDOMAIN=9

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


for (( i=1; i<=${#DOMAIN_ARRAY[@]}; i++ )); do
	if [[ ! -d "/etc/letsencrypt/live/${DOMAIN_ARRAY[$i]}" ]]; then
		[[ -f "/etc/cron.d/${DOMAIN_ARRAY[$i]/./-}" ]] && rm -f /etc/cron.d/${DOMAIN_ARRAY[$i]/./-}
		echo -e "10 ${i} * * 0 root /opt/letsencrypt/letsencrypt-auto renew --no-self-upgrade >>/var/log/letsencrypt_${DOMAIN_ARRAY[$i]}.log\n" >>/etc/cron.d/${DOMAIN_ARRAY[$i]/./-}
		echo -e "40 ${i} * * 0 root /usr/local/bin/bunch_certificates.sh \"${DOMAIN_ARRAY[$i]}\"" >>/etc/cron.d/${DOMAIN_ARRAY[$i]/./-}

		# nginx config
		mkdir /var/www/${DOMAIN_ARRAY[$i]}
		sed -e "s/___SERVERNAME___/${DOMAIN_ARRAY[$i]}/g" \
		    -e "s/___SERVERADMIN___/${EMAIL_ARRAY[$i]}/g" \
		    -e "s/___HOSTNAME___/${HOSTNAME}/g" \
		    /etc/nginx/nginx-letsencrypt.conf >/etc/nginx/conf.d/${DOMAIN_ARRAY[$i]}.conf
		# start nginx
		/usr/sbin/nginx -g "daemon on;"

		# letsencrypt cert
		if /opt/letsencrypt/letsencrypt-auto certonly \
			                              --no-self-upgrade \
			                              --agree-tos \
			                              --email ${EMAIL_ARRAY[$i]} \
			                              --rsa-key-size 4096 \
			                              --webroot \
			                              --webroot-path /var/www/${DOMAIN_ARRAY[$i]} \
			                              --domain ${DOMAIN_ARRAY[$i]}
		then
			# Echo quickstart guide to logs
			echo
			echo '================================================================================='
			echo "Your ${DOMAIN_ARRAY[$i]} letsencrypt container is now ready to use!"
			echo '================================================================================='
			echo

			# Bunch the certs for the first time
			/usr/local/bin/bunch_certificates.sh "${DOMAIN_ARRAY[$i]}"
		else
			echo
			echo '================================================================================='
			echo "Your ${DOMAIN_ARRAY[$i]} letsencrypt container can't get certificates!"
			echo '================================================================================='
			echo

			rm -f  /etc/cron.d/${DOMAIN_ARRAY[$i]/./-}
		fi

		# stop nginx
		/usr/sbin/nginx -s stop
		# nginx config
		rm -f /etc/nginx/conf.d/${DOMAIN_ARRAY[$i]}.conf
		rm -fR /var/www/${DOMAIN_ARRAY[$i]}
	fi
done

/usr/sbin/cron -f -L 15
