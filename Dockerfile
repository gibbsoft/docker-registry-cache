FROM alpine:3.8

RUN apk -U add squid bash ca-certificates libressl openssl curl
COPY ./squid.conf /etc/squid/squid.conf
COPY ./start.sh /bin/start.sh

RUN chmod +x /bin/start.sh

ENV CACHE_SIZE_MB=10000 \
  TARGET_REGISTRY_IP=docker.io \
  TARGET_REGISTRY_PORT=443 \
  HOME=/cache/cc \
  SQUID_CERT_DIR=/etc/squid-cert/ \
  SQUID_CERTDB_DIR=/var/lib/ssl_db/ \
  SQUID_CONF=/etc/squid/squid.conf \
  SQUID_LOG_DIR=/var/log/squid \
  SQUID_PID=/var/run/squid.pid \
  CN=squid.local \
  O=squid \
  OU=squid \
  C=US

RUN touch $SQUID_PID && \
  mkdir -p $HOME $SQUID_CERT_DIR $SQUID_CERTDB_DIR $SQUID_LOG_DIR && \
  chgrp -R 0 $HOME $SQUID_CERT_DIR $SQUID_CERTDB_DIR $SQUID_LOG_DIR $SQUID_CONF $SQUID_PID && \
  chmod -R g=u $HOME $SQUID_CERT_DIR $SQUID_CERTDB_DIR $SQUID_LOG_DIR $SQUID_CONF $SQUID_PID && \
  printf '[ v3_ca ]\n \
  basicConstraints = critical,CA:TRUE\n \
  subjectKeyIdentifier = hash\n \
  authorityKeyIdentifier = keyid:always,issuer:always\n' \
  >> /etc/ssl/openssl.cnf

CMD [ "/bin/start.sh" ]