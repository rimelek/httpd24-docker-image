Environment variables
=====================

Some variables have boolean values. Those values can be set various ways.

| Valid values for **true**: "true", "1", "on", "yes"
| Valid values for **false**: "false", "0", "off", "no"

Each of them is case insensitive.

Variables
---------

SRV_ADMIN
    (default: "you@example.com") "ServerAdmin" directive's value.
SRV_ALLOW_OVERRIDE
    (default: "false") Set it to "true" to enable overriding some configuration from .htaccess. See SRV_ENABLE_MODULE to enable rewrite module.
SRV_AUTH
    (default: "false") Set this to "true" if you need HTTP Basic authentication using an htpasswd file.
    Without SRV_AUTH_USERS you need to create the htpasswd file manually.
SRV_AUTH_NAME
    (default: "Private Area") This is the value of AuthName directive.
SRV_AUTH_USERS
    (default: "") Set the users and their passwords line by line where the user and the password are separated by only one space.
SRV_ENABLE_CONFIG
    (default: "") Pass the name of configurations you want to enable separated by space. There are 3 type of configuration.

    * Official configuration files in "conf/extra" directory. The name of them starts with the name of configuration and ends with ".conf".
      For example: httpd-default.conf. SRV_ENABLE_CONFIG="httpd-default httpd-ssl" will enable httpd-default.conf and httpd-ssl.conf. You will rarely need it.
    * Custom configurations of itsziget/httpd24. These are in "conf/custom-extra" directory.
      To enable these configurations you would need to prefix them with "@". Example: SRV_ENABLE_CONFIG="@php" These are controlled by environment variables so you don't need to enable them this way.
    * Your custom configuration can be saved to "conf/custom-extra/user" directory. If you want to enable them, prefix the configuration names with "@user/".
      Example: SRV_ENABLE_CONFIG="@user/my-conditional-redirect". Of course, the filename must ends with ".conf". See SRV_DISABLE_CONFIG to disable configurations.
SRV_ENABLE_MODULE
    | (default: "") Just like SRV_ENABLE_CONFIG, but this is to enable modules like rewrite.
    | Example: SRV_ENABLE_MODULE="rewrite dav ssl"
    | To disable modules enabled by default use SRV_DISABLE_MODULE.
SRV_DISABLE_CONFIG
    | (default: "") Disable configurations enabled by default. It will comment out the configuration's include.
    | Example: SRV_DISABLE_CONFIG="proxy-html"
SRV_DISABLE_MODULE:
    | (default: "") If you want to disable every module you don't really need, this variable is for you.
    | Example: SRV_DISABLE_MODULE="autoindex"