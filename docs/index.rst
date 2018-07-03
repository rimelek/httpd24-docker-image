.. itsziget/httpd24 documentation master file, created by
   sphinx-quickstart on Mon Jun 11 11:07:41 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to itsziget/httpd24 Docker image's documentation!
=========================================================

Have you heard about `Docker <https://www.docker.com/>`_ (Container engine)? Well, if you ever had problem with installing
dependencies on the same machine for different projects, you should. If you need an `Apache HTTPD <https://hub.docker.com/_/httpd/>`_
web server, you can run it in seconds if you have Docker installed on your machine.

Unfortunately, you almost always need to customize it and create a new image with your own configuration.
Just think of the need of `PHP FPM <https://hub.docker.com/_/php/>`_ or other modules disabled by default.
This documentation is about an enhanced version of the HTTPD 2.4 image inherited from the official version.
It provides a way to customize the configuration by environment variables. PHP FPM configuration was the first reason
of creating this Docker image but now it is just an option among many.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   features
   variables
   examples