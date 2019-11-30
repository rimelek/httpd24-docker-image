import subprocess
import os
import re


class Git(object):
    pattern_stable_version = r"[0-9]+\.[0-9]+\.[0-9]+"
    pattern_dev_version = pattern_stable_version + r"(-[^ ]+)?"
    pattern_minor_branch = '^([0-9]+\\.[0-9]+)(-dev)?$'

    def __init__(self, context):
        self.context = context

    def run_command(self, command, capture_output=False):
        response = subprocess.run(
            f"cd {self.context} && git {command}", shell=True, check=True, capture_output=capture_output)

        return response.stdout.strip().decode("utf-8") if capture_output else ""

    def clone_version(self, version, url):
        os.mkdir(self.context)
        self.run_command(f"clone --branch v{version} {url} .")

    def get_remote_url(self, alias):
        return self.run_command("remote get-url " + alias, capture_output=True)

    def get_last_commit_hash(self):
        return self.run_command("rev-list -n 1 HEAD", capture_output=True)

    def get_versions(self, branch=None, stable=False):
        response = self.run_command("tag --list v[0-9]* --sort -v:refname", capture_output=True)

        pattern_version = Git.pattern_stable_version if stable else Git.pattern_dev_version

        stdout_lines = response.splitlines()
        version_numbers = map(Git.trim_version_flag, stdout_lines)
        semantic_version_numbers = filter(
            lambda x: re.compile("^" + pattern_version + "$").match(x) is not None,
            version_numbers
        )

        if branch:
            semantic_version_numbers = filter(lambda x: re.compile("^" + str(branch).replace(".", "\\.")).match(x),
                                              semantic_version_numbers)

        return list(semantic_version_numbers)

    def get_stable_versions(self, branch=None):
        return self.get_versions(branch=branch, stable=True)

    def get_latest_version(self, branch=None, stable=False):
        return self.get_versions(branch=branch, stable=stable)[0]

    def get_latest_stable_version(self, branch=None):
        return self.get_stable_versions(branch=branch)[0]

    def get_latest_stable_or_pre_version(self, branch):
        latest_version = self.get_latest_stable_version(branch=branch)

        return latest_version if not latest_version else self.get_latest_version(branch=branch)

    @staticmethod
    def is_minor_branch(branch):
        return re.compile(Git.pattern_minor_branch).match(branch)

    @staticmethod
    def trim_version_flag(tag):
        return re.sub(r'^v(.*)', r'\1', tag)
