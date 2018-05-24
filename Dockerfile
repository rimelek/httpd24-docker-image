FROM httpd:2.4

LABEL maintainer="rimelek@it-sziget.hu"

ENV SRV_REVERSE_PROXY_DOMAIN="" \
    SRV_REVERSE_PROXY_CLIENT_IP_HEADER="X-Forwarded-For" \
    SRV_SSL="false" \
    SRV_SSL_LETSENCRYPT="false" \
    SRV_SSL_CERT="" \
    SRV_SSL_KEY="" \
    SRV_SSL_NAME="" \
    SRV_SSL_AUTO="false" \
    SRV_AUTH="false" \
    SRV_AUTH_NAME="Private Area" \
    SRV_AUTH_USERS="" \
    SRV_ADMIN="" \
    SRV_NAME="" \
    SRV_DOCROOT="" \
    SRV_PHP="false" \
    SRV_PHP_HOST="php" \
    SRV_PHP_PORT="9000" \
    SRV_PHP_TIMEOUT="60" \
    SRV_ENABLE_CONF="" \
    SRV_DISABLE_CONF="" \
    SRV_ENABLE_MODULE="" \
    SRV_DISABLE_MODULE="" \
    SRV_ALLOW_OVERRIDE="false"

COPY apache2 /usr/local/apache2

RUN chmod +x /usr/local/apache2/bin/start.sh \
 && for i in $(ls -A "/usr/local/apache2/conf/custom-extra"); do \
        echo "#Include conf/custom-extra/${i}" >> "/usr/local/apache2/conf/httpd.conf"; \
    done \
 && echo "ServerName localhost.localdomain" >> "/usr/local/apache2/conf/httpd.conf" \
 && mkdir /usr/local/apache2/ssl
    

EXPOSE 80 443

CMD ["/usr/local/apache2/bin/start.sh"]