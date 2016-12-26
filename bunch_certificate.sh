#!/bin/bash

# This script is among others usefull with HAProxy (need a file containing the certificate and its associated private key)

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="${BASH_SOURCE[0]##*/}"
__bas0="${__base%.sh}"

DOMAIN=$1

LETSENCRYPT_CERTS_DIR="/etc/letsencrypt/live/"

update_cert() {
	cat ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/cert.pem    \
	    ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/chain.pem   \
	    ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/privkey.pem \
	  > ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/${DOMAIN}.pem

	openssl sha1 -r ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/${DOMAIN}.pem | awk '{print $1}' >${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/${DOMAIN}.sha1
}


[[ -z "${DOMAIN}" ]] && exit 0
[[ -d ${LETSENCRYPT_CERTS_DIR} ]] || exit 0
[[ -d ${LETSENCRYPT_CERTS_DIR}/${DOMAIN} ]] || exit 0


if [[ -f ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/${DOMAIN}.pem && -f ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/${DOMAIN}.sha1 ]]; then
	sha1sum=$(cat ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/cert.pem \
	              ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/chain.pem \
	              ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/privkey.pem | \
	          openssl sha1 -r | \
	          awk '{print $1}')
	if [ "${sha1sum}" != "$(cat ${LETSENCRYPT_CERTS_DIR}/${DOMAIN}/${DOMAIN}.sha1)" ]; then
		# Letsencrypt certs changed
		update_cert
	fi
else
	# New Letsencrypt certs
	update_cert
fi
