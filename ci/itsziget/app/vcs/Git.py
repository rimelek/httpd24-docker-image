import subprocess
import os


class Git(object):
    context = None

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


