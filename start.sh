#!/bin/bash -ex

set -e

interpolate_template() {
    sed "s/<<CACHE_SIZE_MB>>/$CACHE_SIZE_MB/g" /etc/squid.conf >/tmp/squid.conf && cat /tmp/squid.conf >/etc/squid.conf
    sed "s/<<REGISTRY_IP>>/$TARGET_REGISTRY_IP/g" /etc/squid.conf >/tmp/squid.conf && cat /tmp/squid.conf >/etc/squid.conf
    sed "s/<<REGISTRY_PORT>>/$TARGET_REGISTRY_PORT/g" /etc/squid.conf >/tmp/squid.conf && cat /tmp/squid.conf >/etc/squid.conf
    sed "s@<<HOME>>@$HOME@g" /etc/squid.conf >/tmp/squid.conf && cat /tmp/squid.conf >/etc/squid.conf
}

initialize_cache() {
    echo "Creating cache folder..."
    /usr/sbin/squid -N -z -f /etc/squid.conf
    sleep 5
}

create_cert() {
    if [ ! -f /etc/squid-cert/private.pem ]; then
        echo "Creating certificate..."
        openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
            -extensions v3_ca -keyout /etc/squid-cert/private.pem \
            -out /etc/squid-cert/private.pem \
            -subj "/CN=$CN/O=$O/OU=$OU/C=$C" -utf8 -nameopt multiline,utf8

        openssl x509 -in /etc/squid-cert/private.pem \
            -outform DER -out /etc/squid-cert/CA.der

        openssl x509 -inform DER -in /etc/squid-cert/CA.der \
            -out /etc/squid-cert/CA.pem
    else
        echo "Certificate found..."
    fi
}

clear_certs_db() {
    echo "Clearing generated certificate db..."
    local dest=/var/lib/ssl_db

    rm -rfv ${dest:?}/*
    /usr/lib/squid/ssl_crtd -c -s /tmp/ssl_db
    mv /tmp/ssl_db/* ${dest}
    rmdir /tmp/ssl_db
}

run() {
    echo "Starting squid..."
    interpolate_template
    create_cert
    clear_certs_db
    initialize_cache
    exec /usr/sbin/squid -NYCd 5 -f /etc/squid/squid.conf
}

run
