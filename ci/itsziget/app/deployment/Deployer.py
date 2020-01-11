import semantic_version

from itsziget.app import container, vcs


class Deployer(object):

    def __init__(self, git: vcs.Git,
                 current_version: str = None,
                 latest_version: str = None,
                 latest_minor: str = None,
                 latest_major: str = None,
                 image_name: str = None,
                 image_tag: str = None,
                 use_semantic_version: bool = False,
                 custom_tags: list = None
                 ):

        self.docker = container.DockerManager()
        self.git = git

        self.current_version = current_version
        self.latest_version = latest_version
        self.latest_minor = latest_minor
        self.latest_major = latest_major
        self.image_name = image_name
        self.image_tag = image_tag
        self.use_semantic_version = use_semantic_version
        self.custom_tags = custom_tags

    def tag(self, version_tag):
        self.docker.tag_image(self.image_name + ":" + self.image_tag, self.image_name + ":" + version_tag)

    def push(self, version_tag):
        self.docker.push_image(self.image_name + ":" + version_tag)

    def push_as(self, version_tag):
        self.docker.push_image_as(self.image_name + ":" + self.image_tag, self.image_name + ":" + version_tag)

    def deploy(self):
        current_valid = semantic_version.validate(self.current_version)
        latest_valid = semantic_version.validate(self.latest_version)
        latest_minor = self.latest_minor
        latest_major = self.latest_major
        latest_version = self.latest_version

        if not self.image_name:
            raise Exception("image_name is empty")

        if self.current_version:
            if not current_valid:
                raise Exception(f"Invalid current_version: {self.current_version}")

            if not latest_valid and self.latest_version:
                raise Exception(f"Invalid latest_version: {self.latest_version}")

            self.push_as(self.current_version)

            current_semver = semantic_version.Version(self.current_version)
            is_prerelease = len(current_semver.prerelease) > 0
            if self.use_semantic_version or is_prerelease:
                if not latest_minor:
                    latest_minor = self.git.get_latest_stable_version(current_semver.major + "." + current_semver.minor)
                if not latest_major:
                    latest_major = self.git.get_versions(major=current_semver.major)
                if not latest_version:
                    latest_version = self.git.get_latest_stable_version()

                if semantic_version.Version(latest_minor) == current_semver:
                    self.push_as(current_semver.major + "." + current_semver.minor)
                if semantic_version.Version(latest_major) == current_semver:
                    self.push_as(current_semver.major)
                if semantic_version.Version(latest_version) == current_semver and latest_version:
                    self.push_as("latest")

        self.push_as(self.git.get_last_commit_hash())

        for custom_tag in self.custom_tags:
            self.push_as(custom_tag)

