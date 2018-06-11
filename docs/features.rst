Features
========

* Change some default server settings like ServerName, ServerAdmin, DocumentRoot and LogLevel
* Configure HTTPD to connect PHP FPM and increase timeout if you need.
* Turn SSL on or off easily. You can even generate a self-signed certificate to test locally and optionally redirect all HTTP requests to HTTPS.
* Do you use Reverse proxy front of the web server? You may want to log the original client IP address in the HTTPD container
  instead of the proxy's IP. You are free to use
  `ProxyProtocol <https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html#remoteipproxyprotocol>`_ or set
  `RemoteIPInternalProxy <https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html#remoteipinternalproxy>`_.
* Turn HTTP Basic authentication on or off. You can mount your own htpasswd file or generate it automatically from environment variable.
* Use HTTPD as reverse proxy to proxy one url to another.
* Mount your own configuration or copy that into your own image and enable or disable it.
* Run any custom command when httpd is ready to run but before it actually runs, so you can change anything before that.
* Enable/Disable modules or custom and built-in configurations without changing httpd.conf manually