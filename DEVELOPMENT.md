# Development

## Getting Started

Before you get started, we recommend installing [Node Version Manager](https://github.com/nvm-sh/nvm#installing-and-updating) to help manage `node` and `npm` versions. Next, from your local copy of the action run `nvm use` and `npm install`. You're ready to start coding!

## Git Workflows

We use the [feature branch workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow). The workflow for a typical code change looks like this:

1. Create a new branch for the feature.
2. Make changes to the code.
3. Use `npx changeset` to create a changeset describing the change to users.
4. Commit your changes.
5. Open a pull request to the `main` branch.
6. Once all checks are passing and the PR is approved, Squash and Merge into the `main` branch.

## Creating a release

We use [Changesets](https://github.com/changesets/changesets) to automate versioning and releasing. When you are ready to release, the first step is to create the new version.

1. Go to pull requests and view the automated "Version Image" PR.
2. Review the PR:
    - [ ] Changelog entries were created.
    - [ ] Version number in package.json was bumped.
    - [ ] All `.changeset/*.md` files were removed.
3. Approve, then "Squash and merge" the PR into `main`.

Merging the versioning PR will run a workflow that creates or updates all necessary tags. It will also create a new release in GitHub.

## Updating the Docker Image

The `Dockerfile` is hosted as a Docker image on DockerHub: [wpengine/sitedeploy](https://hub.docker.com/r/wpengine/site-deploy).

The Docker image is used in both [wpengine/github-action-wpe-site-deploy](https://github.com/wpengine/github-action-wpe-site-deploy) GitHub Action and the [wpengine/wpe-site-deploy]([https://bitbucket.org/azunigawpe/wpe-bb-deploy/src/main/](https://bitbucket.org/wpengine/wpe-site-deploy/src/main/)) Bitbucket Pipe. Any customizations to the image should consider the effect on both services.

Images are also pushed to an internal registry for vulnerability scanning; customers continue to pull from Docker Hub.

### Automatic Builds

Docker images are built and pushed automatically to Docker Hub and the internal registry by the reusable `docker-build-push.yml` workflow:

| Trigger | Tags Updated | Source |
|---------|--------------|--------|
| New version release | `latest`, `vX`, `vX.Y`, `vX.Y.Z` | GitHub Actions |
| Monthly schedule (1st of month) | `latest`, `vX`, `vX.Y`, `vX.Y.Z` | GitHub Actions |
| Manual trigger | `latest`, `vX`, `vX.Y`, `vX.Y.Z` | GitHub Actions |

The scheduled monthly rebuild ensures security patches are applied even when there are no new releases. All builds use `no-cache` to pull fresh base image layers.

Every build is tested before anything is pushed. `docker-build-push.yml` builds the image once, runs `make test-image`, and deploys the e2e test plugin to the `sitedeploye2e` site using that image. The same image is then pushed to both registries. If any check fails, nothing is pushed.

The e2e site is shared with the `e2e-deploy.yml` workflow, so both use the `e2e-sitedeploye2e` concurrency group. GitHub keeps only one pending run per group, so a build waiting behind a running e2e can be cancelled by a newer run. If a release or monthly rebuild shows as cancelled, re-run it.

The internal registry only accepts pushes from `docker-build-push.yml` running on `main`, so manual runs of the scheduled rebuild must be dispatched from `main`, and the workflow file must not be renamed.

### Base Image Maintenance

The Dockerfile uses the current Ubuntu LTS release as its base image. The base image follows this update pattern:

- Ubuntu releases a new LTS version every 2 years (in April of even years)
- **Dependabot** is configured to ignore minor and major `ubuntu` updates, so it never proposes a non-LTS release. Moving to a new LTS is a manual task.
- **Scheduled rebuilds** pick up security patches from `apt-get upgrade` monthly

When a new Ubuntu LTS is released:

1. Review the [Ubuntu release notes](https://wiki.ubuntu.com/Releases) for breaking changes.
2. Update the `FROM` line in the `Dockerfile` and ensure tests are passing, including `make test-image`.
3. Compare `rsync --version`, `ssh -V` and `bash --version` against the previous image, and add a changeset (`npx changeset`) that lists any changes so a proper release is created when merged
4. Merge the PR to trigger a new versioned release

## Building and versioning locally

You can also build and version this image using make targets when necessary.

```
make build       # Builds the image locally
make version     # Builds the image and creates version tags
make list-images # Shows all tagged versions of the image
make clean       # Deletes all tagged versions of the image
make test-unit   # Runs the shell tests on the host
make test-image  # Builds the image and runs the shell tests inside it
```

`make test-image` runs the tests with the image's own `bash`, `rsync`, `find` and `xargs`, which can behave differently from the versions on your machine.
