import os
import pytest


class TestRunner(object):
    environment = []

    def __init__(self, environment=None):
        if environment is not None:
            self.environment = environment

    def run(self):
        for key, value in self.environment.items():
            os.environ[key] = value

        pytest.main(["test"])
