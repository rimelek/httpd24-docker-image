# README

Docker image for HTTPD 2.4 based on the [official httpd image on Docker Hub](https://hub.docker.com/_/httpd).

For historical reasons the built Docker image can be pulled from two repositories on Docker Hub.
From the old "free team organization": [itsziget/httpd24](https://hub.docker.com/r/itsziget/httpd24/).
From my original personal namespace (recommended): [rimelek/httpd24](https://hub.docker.com/r/rimelek/httpd24)

I advertised `itsziget/httpd24` as the main repository for years when the sourcecode was stored on GitHub under
an organization with the same name (itsziget), but I decided to move everything back to my personal account.
Although I am going to keep the repository under itsziget indefinitely, `rimelek/httpd24` is the recommended now
as this cannot be affected by events like the
[attempt to disabling the free team organizations](https://www.docker.com/blog/no-longer-sunsetting-the-free-team-plan/)
and I am using the vulnerability scan feature enabled in my personal PRO account.

If you have any question about this change, please, open an issue and I am happy to answer it.

The build is automated using [CircleCI](https://circleci.com/)

For the detailed documentation see one of the following pages:

* **\>=2.0**: https://httpd24-docker-image.readthedocs.io
* **1.1**:  https://github.com/rimelek/httpd24-docker-image/blob/1.1/README.md
* **1.0**: https://github.com/rimelek/httpd24-docker-image/blob/1.0/README.md