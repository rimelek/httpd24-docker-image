import argparse
import os

PARENT_IMAGE = "httpd:2.4"
PROJECT_ROOT = os.path.dirname(os.path.realpath(__file__ + "/../../.."))
BUILD_DIR = PROJECT_ROOT + "/.build"


class BuildArgumentParser(argparse.ArgumentParser):

    def __init__(self, default_build_number=None):
        super().__init__(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        self.add_argument("-d", "--dry-run",
                          help="Do not actually run, but show what would happen", action="store_true")
        self.add_argument("-t", "--tag",
                          help="VCS tag")
        self.add_argument("-b", "--branch",
                          help="VCS branch")
        self.add_argument("-T", "--docker-start-timeout",
                          help="How many seconds can the tester wait to start the container", type=int, default=180)
        self.add_argument("-i", "--image-name",
                          help="Desired name of the Docker image without version tag", required=True)
        self.add_argument("-s", "--skip-test",
                          help="Skip the test of the built image", action="store_true")
        self.add_argument("-r", "--repository-alias",
                          help="Remote repository alias", default="origin")
        self.add_argument("-B", "--build-number",
                          help="A unique build number to distinguish between different builds."
                               "Git commit hash can be a good idea.",
                          default=default_build_number)
        self.add_argument("-e", "--event-type",
                          help="The type of CI event.", choices=["push", "api", "cron"], required=True)

