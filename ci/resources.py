import subprocess
import re
import argparse
import os
import pytest

GIT_HASH = subprocess.run(["git", "rev-list", "-n", "1", "HEAD"], capture_output=True, text=True).stdout.strip()
PATTERN_MINOR_BRANCH = '^([0-9]+\\.[0-9]+)(-dev)?$'
PATTERN_STABLE_VERSION = '[0-9]+\\.[0-9]+\\.[0-9]+'
PARENT_IMAGE = "httpd:2.4"
PROJECT_ROOT = os.path.dirname(os.path.realpath(__file__ + "/.."))


class BuildArgumentParser(argparse.ArgumentParser):

    def __init__(self):
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
                          default=GIT_HASH)
        self.add_argument("-e", "--event-type",
                          help="The type of CI event.", choices=["push", "api", "cron"], required=True)


def is_minor_branch(branch):
    return re.compile(PATTERN_MINOR_BRANCH).match(branch)


def trim_version_flag(tag):
    return re.sub(r'^v(.*)', r'\1', tag)


def get_versions(**kwargs):
    branch = kwargs.get("branch")
    stable = kwargs.get("stable")

    stdout = str(subprocess.run(
        ["git", "tag", "--list", "v[0-9]*", "--sort", "-v:refname"], capture_output=True, text=True).stdout)

    dev_suffix_pattern = "" if stable else "(-[^ ]+)?"

    stdout_lines = stdout.strip().splitlines()
    version_numbers = map(trim_version_flag, stdout_lines)
    semantic_version_numbers = filter(
        lambda x: re.compile("^" + PATTERN_STABLE_VERSION + dev_suffix_pattern + "$").match(x) is not None,
        version_numbers
    )

    if branch:
        semantic_version_numbers = filter(lambda x: re.compile("^" + str(branch).replace(".", "\\.")).match(x),
                                          semantic_version_numbers)

    return list(semantic_version_numbers)


def get_stable_versions(**kwargs):
    branch = kwargs.get("branch")
    return get_versions(branch=branch, stable=True)


def get_latest_version(**kwargs):
    branch = kwargs.get("branch")
    stable = kwargs.get("stable")

    return get_versions(branch=branch, stable=stable)[0]


def get_latest_stable_version(**kwargs):
    branch = kwargs.get("branch")
    return get_stable_versions(branch=branch)[0]


def get_latest_stable_or_pre_version(branch):
    latest_version = get_latest_stable_version(branch=branch)

    return latest_version if not latest_version else get_latest_version(branch=branch)
