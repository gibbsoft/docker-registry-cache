#!/bin/bash -ex

set -e

interpolate_template() {
    sed "s/<<CACHE_SIZE_MB>>/$CACHE_SIZE_MB/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s/<<REGISTRY_IP>>/$TARGET_REGISTRY_IP/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s/<<REGISTRY_PORT>>/$TARGET_REGISTRY_PORT/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s/<<APPLICATION_NAME>>/$APPLICATION_NAME/g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
    sed "s@<<HOME>>@$HOME@g" $SQUID_CONF >/tmp/squid.conf && cat /tmp/squid.conf >$SQUID_CONF
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
    clear_certs_db
    initialize_cache
    exec /usr/sbin/squid -NYCd 5 -f $SQUID_CONF
}

run
