import os
import shutil
from itsziget.app import container, tester, resources, vcs
import docker.errors as docker_errors

git_main = vcs.Git(os.path.abspath(resources.PROJECT_ROOT))  # project level git
git_build = vcs.Git(os.path.abspath(resources.BUILD_DIR))  # switch to the temporary build dir

args = resources.BuildArgumentParser(default_build_number=git_main.get_last_commit_hash()).parse_args()

if args.tag is not None:
    args.branch = args.tag

if not args.branch:
    raise Exception("Either --branch or --tag must be set")

docker = container.DockerManager()
testRunner = tester.TestRunner(image_name=args.image_name, docker_start_timeout=args.docker_start_timeout)


if args.event_type == "cron":
    if args.branch != args.tag:
        if vcs.Git.is_minor_branch(args.branch):
            latest_version = git_main.get_latest_stable_or_pre_version(args.branch)
            if latest_version:
                version_cache = latest_version

                print(f"docker pull {args.image_name}:{version_cache}")
                if not args.dry_run:
                    docker.pull_image(args.image_name, version_cache)

                if os.path.isdir(resources.BUILD_DIR):
                    shutil.rmtree(resources.BUILD_DIR)

                repository_url = git_main.get_remote_url(args.repository_alias)
                git_build.clone_version(latest_version, repository_url)
                os.chdir(resources.BUILD_DIR)

                docker.pull_image("httpd", "2.4")

                image = args.image_name + ":" + git_build.get_last_commit_hash()
                if docker.is_image_downloaded(image) and docker.is_parent_image_upgraded(image, "httpd:2.4"):
                    print(f"docker build --pull --cache-from {args.image_name}:{version_cache}"
                          f" --tag {image} --tag {args.image_name}:build-{args.build_number}")
                    if not args.dry_run:
                        docker.build_image(f"{args.image_name}:{version_cache}", [
                            f"{image}",
                            f"{args.image_name}:build-{args.build_number}",
                        ])

                    if not args.skip_test and os.path.exists("test/__init__.py"):
                        testRunner.run(git_build.get_last_commit_hash())

else:
    git_hash = git_main.get_last_commit_hash()
    version_cache = args.branch + "-dev" if args.branch != args.tag else git_hash

    print(f"docker pull {args.image_name}:{version_cache}")
    if not args.dry_run:
        try:
            docker.pull_image(args.image_name, version_cache)
        except docker_errors.ImageNotFound:
            print(f"Notice: There is no built image named {args.image_name}:{version_cache} for cache")

    if args.branch != args.tag:
        print(f"docker build --pull --cache-from {args.image_name}:{version_cache}"
              f" --tag {args.image_name}:{git_hash}")
        if not args.dry_run:
            docker.build_image(f"{args.image_name}:{version_cache}", f"{args.image_name}:{git_hash}")
            if not args.skip_test:
                testRunner.run(git_hash)
