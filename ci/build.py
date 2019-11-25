import resources
import subprocess
import os
import shutil
import pytest

args = resources.BuildArgumentParser().parse_args()

if args.tag is not None:
    args.branch = args.tag

# TODO: make branch or a tag required

if args.event_type == "cron":
    if args.branch == args.tag:
        if resources.is_minor_branch(args.branch):
            latest_version = resources.get_latest_stable_or_pre_version(args.branch)
            if latest_version:
                version_cache = latest_version
                command = ["docker", "pull",  f"{args.image_name}:{version_cache}"]
                print(subprocess.list2cmdline(command))

                if not args.dry_run:
                    subprocess.run(command)

                build_dir = resources.PROJECT_ROOT + "/.build"
                if os.path.isdir(build_dir):
                    shutil.rmtree(build_dir)

                repository_url = subprocess.getoutput("git remote get-url " + args.repository_alias)
                subprocess.run(["git", "clone", "--branch", "v" + latest_version, repository_url, build_dir])
                os.chdir(build_dir)

                # update git commit hash
                resources.GIT_HASH = subprocess.getoutput("git rev-list -n 1 HEAD")
                subprocess.run(["docker", "pull", "httpd:2.4"])

                image = args.image_name + ":" + resources.GIT_HASH
                print(resources.is_parent_image_upgraded(image, "httpd:2.4"))
                if resources.is_image_downloaded(image) and resources.is_parent_image_upgraded(image, "httpd:2.4"):
                    command = [
                        "docker", "build", "--pull",
                        "--cache-from" f"{args.image_name}:{version_cache}",
                        "--tag" f"{image}",
                        "--tag", f"{args.image_name}:build-{args.build_number}",
                        ".",
                    ]

                    print(subprocess.list2cmdline(command))
                    if not args.dry_run:
                        subprocess.run(command)

                    if not args.skip_test and os.path.exists("test/__init__.py"):
                        pytest.main()
