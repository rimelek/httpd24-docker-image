import os
import pytest


class TestRunner(object):
    def __init__(self, image_name=None, docker_start_timeout=None):
        self.environment = {
            "HTTPD_IMAGE_NAME": image_name,
            "HTTPD_IMAGE_TAG": None,
            "HTTPD_WAIT_TIMEOUT": str(docker_start_timeout)
        }

    def run(self, httpd_image_tag):
        self.environment["HTTPD_IMAGE_TAG"] = httpd_image_tag

        for key, value in self.environment.items():
            os.environ[key] = value

        pytest.main(["test"])
