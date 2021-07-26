#!/bin/bash -ex

set -e

interpolate_template() {
    sed "s/<<CACHE_SIZE_MB>>/$CACHE_SIZE_MB/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s/<<REGISTRY_IP>>/$TARGET_REGISTRY_IP/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s/<<REGISTRY_PORT>>/$TARGET_REGISTRY_PORT/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s/<<APPLICATION_NAME>>/$APPLICATION_NAME/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s@<<HOME>>@$HOME@g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
}

create_cert() {
    if [ ! -f "/etc/$APPLICATION_NAME/tls.key" ]; then
        echo "Creating certificate..."
        openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
            -extensions v3_ca -keyout "/etc/$APPLICATION_NAME/tls.key" \
            -out "/etc/$APPLICATION_NAME/tls.key" \
            -subj "/CN=$CN/O=$O/OU=$OU/C=$C" -utf8 -nameopt multiline,utf8

        openssl x509 -in "/etc/$APPLICATION_NAME/tls.key" \
            -outform DER -out "/etc/$APPLICATION_NAME/tls.der"

        openssl x509 -inform DER -in "/etc/$APPLICATION_NAME/tls.der" \
            -out "/etc/$APPLICATION_NAME/tls.crt"
    else
        echo "Certificate found..."
    fi
}

initialize_cache() {
    echo "Creating cache folder..."
    /usr/sbin/squid -N -z -f $SQUID_CONF
    sleep 5
}

clear_certs_db() {
    echo "Clearing generated certificate db..."
    local dest=/var/lib/ssl_db

    rm -rfv ${dest:?}/*
    /usr/lib/squid/ssl_crtd -c -s /tmp/ssl_db -M 4MB
    mv /tmp/ssl_db/* ${dest}
    rmdir /tmp/ssl_db
}

run() {
    echo "Starting squid..."
    interpolate_template
    create_cert
    clear_certs_db
    initialize_cache
    exec /usr/sbin/squid -NYCd 5 -f $SQUID_CONF
}

run
