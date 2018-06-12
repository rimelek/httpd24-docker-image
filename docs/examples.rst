Examples
========

Using SSL certificate
---------------------

With Let's Encrypt without custom certificate name
+++++++++++++++++++++++++++++++++++++++++++++++++++

.. code-block:: bash

    docker run -d \
       --env SRV_SSL="true" \
       --env SRV_LETSENCRYPT="true" \
       --env SRV_NAME=YOURDOMAIN \
       -v /etc/letsencrypt:/etc/letsencrypt \
       -p 443:443 \
       itsziget/httpd24:2.0

With Let's Encrypt and custom certificate name
+++++++++++++++++++++++++++++++++++++++++++++++

.. code-block:: bash

    docker run -d \
       --env SRV_SSL="true" \
       --env SRV_LETSENCRYPT="true" \
       --env SRV_NAME=YOURDOMAIN \
       --env CERT_NAME=CUSTOMCERTNAME \
       -v /etc/letsencrypt:/etc/letsencrypt \
       -p 443:443 \
       itsziget/httpd24:2.0

You can mount custom certificate two ways
++++++++++++++++++++++++++++++++++++++++++

.. code-block:: bash

    docker run -d \
       --env SRV_SSL="true" \
       -v /path/to/custom.key:/usr/local/apache2/ssl.key \
       -v /path/to/custom.crt:/usr/local/apache2/ssl.crt \
       -p 443:443 \
       itsziget/httpd24:2.0

or

.. code-block:: bash

    docker run -d \
       --env SRV_SSL="true" \
       --env SRV_CERT=/ssl.crt \
       --env SRV_CERT_KEY=/ssl.key \
       -v /path/to/custom.key:/ssl.key \
       -v /path/to/custom.crt:/ssl.crt \
       -p 443:443 \
       itsziget/httpd24:2.0


HTTP Authentication
-------------------

.. code-block:: bash

    docker run --rm -i itsziget/httpd24 /bin/bash -c "htpasswd -nb YOURUSERNAME YOURPASSWORD" >> .htpasswd
    docker run -d \
       -v `pwd`/.htpasswd:/usr/local/apache2/.htpasswd \
       --env SRV_AUTH="true" \
       -p 80:80 \
       itsziget/httpd24:2.0

or just generate htpasswd inside the container

.. code-block:: bash

    docker run -d \
       --env SRV_AUTH="true" \
       --env SRV_AUTH_USERS="admin1 password1\
     admin2 password2"
       -p 80:80 \
       itsziget/httpd24:2.0


Simplest way to use PHP-FPM
---------------------------

Legacy way
++++++++++

.. code-block:: bash

    mkdir -p src
    echo "<?php phpinfo(); " > src/index.php
    docker run -d \
       -v $PWD/src:/usr/local/apache2/htdocs \
       --name php \
       php:7.1-fpm
    docker run -d \
       --volumes-from php \
       --env SRV_PHP="true" \
       -p "80:80" \
       --link php \
       itsziget/httpd24:2.0

Recommended way
+++++++++++++++

.. code-block:: bash

    mkdir -p src
    echo "<?php phpinfo(); " > src/index.php
    docker network create phptest
    docker run -d \
       -v $PWD/src:/usr/local/apache2/htdocs \
       --name php \
       --network phptest \
       php:7.1-fpm
    docker run -d \
       --volumes-from php \
       --env SRV_PHP=1 \
       -p "80:80" \
       --network phptest \
       itsziget/httpd24:2.0


Reusing the network of the HTTPD container
++++++++++++++++++++++++++++++++++++++++++

.. code-block:: bash

    mkdir -p src
    echo "<?php phpinfo(); " > src/index.php
    docker run -d \
       -v $PWD/src:/usr/local/apache2/htdocs \
       --name php \
       -p "80:80" \
       php:7.1-fpm
    docker run -d \
       --volumes-from php \
       --env SRV_PHP=1 \
       --env SRV_PHP_HOST=localhost \
       --network container:php \
       itsziget/httpd24:2.0


Use the rewrite engine
----------------------

.. code-block:: bash

    docker run -d \
        -v $PWD/src:/usr/local/apache2/htdocs \
        -p 80:80 \
        --env SRV_ENABLE_MODULES="rewrite" \
        --env SRV_ALLOW_OVERRIDE="true" \
        itsziget/httpd24:2.0

Forward the admin page to another site:
---------------------------------------

.. code-block:: bash

    docker run -d \
        -v $PWD/src:/usr/local/apache2/htdocs \
        -p 80:80 \
        --env SRV_PROXY_FORWARD_FROM="/admin/" \
        --env SRV_PROXY_FORWARD_TO="http://admin.mysite.tld/" \
        itsziget/httpd24:2.0


Get real client IP behind reverse proxy
---------------------------------------

Proxy protocol
++++++++++++++

.. code-block:: bash

    docker run -d \
        -v $PWD/src:/usr/local/apache2/htdocs \
        -p 80:80 \
        --env SRV_PROXY_PROTOCOL="true" \
        itsziget/httpd24:2.0

Client IP header
++++++++++++++++

.. code-block:: bash

    docker run -d \
        -v $PWD/src:/usr/local/apache2/htdocs \
        -p 80:80 \
        --env SRV_REVERSE_PROXY_CLIENT_IP_HEADER="X-Forwarded-For" \
        --env SRV_REVERSE_PROXY_DOMAIN="haproxy" \
        itsziget/httpd24:2.0