import resources
import subprocess
import os
import shutil
import pytest
import container
import docker.errors as docker_errors

args = resources.BuildArgumentParser().parse_args()

if args.tag is not None:
    args.branch = args.tag

if not args.branch:
    raise Exception("Either --branch or --tag must be set")

docker = container.DockerManager()


if args.event_type == "cron":
    if args.branch != args.tag:
        if resources.is_minor_branch(args.branch):
            latest_version = resources.get_latest_stable_or_pre_version(args.branch)
            if latest_version:
                version_cache = latest_version

                print(f"docker pull {args.image_name}:{version_cache}")
                if not args.dry_run:
                    docker.pull_image(args.image_name, version_cache)

                build_dir = resources.PROJECT_ROOT + "/.build"
                if os.path.isdir(build_dir):
                    shutil.rmtree(build_dir)

                repository_url = subprocess.getoutput("git remote get-url " + args.repository_alias)
                subprocess.run(["git", "clone", "--branch", "v" + latest_version, repository_url, build_dir])
                os.chdir(build_dir)

                # update git commit hash
                resources.GIT_HASH = subprocess.getoutput("git rev-list -n 1 HEAD")
                docker.pull_image("httpd", "2.4")

                image = args.image_name + ":" + resources.GIT_HASH
                if docker.is_image_downloaded(image) and docker.is_parent_image_upgraded(image, "httpd:2.4"):
                    print(f"docker build --pull --cache-from {args.image_name}:{version_cache}"
                          f" --tag {image} --tag {args.image_name}:build-{args.build_number}")
                    if not args.dry_run:
                        docker.build_image(f"{args.image_name}:{version_cache}", [
                            f"{image}",
                            f"{args.image_name}:build-{args.build_number}",
                        ])

                    if not args.skip_test and os.path.exists("test/__init__.py"):
                        os.environ["HTTPD_IMAGE_NAME"] = args.image_name
                        os.environ["HTTPD_IMAGE_TAG"] = resources.GIT_HASH
                        os.environ["HTTPD_WAIT_TIMEOUT"] = str(args.docker_start_timeout)
                        pytest.main(["test"])
else:
    version_cache = args.branch + "-dev" if args.branch != args.tag else resources.GIT_HASH

    print(f"docker pull {args.image_name}:{version_cache}")
    if not args.dry_run:
        try:
            docker.pull_image(args.image_name, version_cache)
        except docker_errors.ImageNotFound:
            print(f"Notice: There is no built image named {args.image_name}:{version_cache} for cache")

    if args.branch != args.tag:
        print(f"docker build --pull --cache-from {args.image_name}:{version_cache}"
              f" --tag {args.image_name}:{resources.GIT_HASH}")
        if not args.dry_run:
            docker.build_image(f"{args.image_name}:{version_cache}", f"{args.image_name}:{resources.GIT_HASH}")
            if not args.skip_test:
                os.environ["HTTPD_IMAGE_NAME"] = args.image_name
                os.environ["HTTPD_IMAGE_TAG"] = resources.GIT_HASH
                os.environ["HTTPD_WAIT_TIMEOUT"] = str(args.docker_start_timeout)
                pytest.main(["test"])
