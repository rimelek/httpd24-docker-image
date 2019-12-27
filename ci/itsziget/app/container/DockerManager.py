import docker
import docker.errors
import json


class DockerManager(object):

    api = docker.APIClient(base_url="unix:///var/run/docker.sock")

    def get_image_layers(self, image):
        inspection = self.api.inspect_image(image)
        return inspection.get("RootFS").get("Layers")

    def is_parent_image_upgraded(self, image, parent_image):
        latest_parent_layer = self.get_image_layers(parent_image).pop()
        layers = self.get_image_layers(image)

        return latest_parent_layer not in layers

    def is_image_downloaded(self, image):
        try:
            self.api.inspect_image(image)
            return True
        except docker.errors.ImageNotFound:
            return False

    def pull_image(self, repository, tag):
        response = self.api.pull(repository, tag, stream=True, decode=True)
        for line in response:
            print(line)

    def build_image(self, cache_from, names, path=None):
        if not isinstance(cache_from, list):
            cache_from = [cache_from]

        if not isinstance(names, list):
            names = [names]

        if path is None:
            path = "."

        response = self.api.build(cache_from=cache_from, tag=names[0], path=path, pull=True)

        for line in response:
            print(json.loads(line.decode('utf-8')))

        if len(names) > 1:
            self.tag_image(names[0], names[1:])

    def tag_image(self, image, aliases):

        if not isinstance(aliases, list):
            aliases = [aliases]

        for alias in aliases:
            repository, tag, *rest = alias.rsplit(":", 1) + [None]
            if self.api.tag(image, repository, tag):
                print(f"Successfully tagged {repository}:{tag}")
            else:
                raise Exception(f"Failed to tag {repository}:{tag}")

    def push_image(self, images):
        if not isinstance(images, list):
            images = [images]

        for image in images:
            repository, tag, *rest = image.rsplit(":", 1) + [None]
            self.api.push(repository, tag=tag)

    def push_image_as(self, image, aliases):
        self.tag_image(image, aliases)

        if not isinstance(aliases, list):
            aliases = [aliases]

        for alias in aliases:
            self.push_image(alias)
