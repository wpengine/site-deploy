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

1. Go to pull requests and view the "Version Action" PR.
2. Review the PR:
    - [ ] Changelog entries were created.
    - [ ] Version number in package.json was bumped.
    - [ ] All `.changeset/*.md` files were removed.
3. Approve, then "Squash and merge" the PR into `main`.

Merging the versioning PR will run a workflow that creates or updates all necessary tags. It will also create a new release in GitHub.

## Managing the Dockerfile & Docker Image

The `Dockerfile` is hosted as a Docker image on DockerHub: [wpengine/sitedeploy](https://hub.docker.com/r/wpengine/site-deploy).

The Docker image is used in both [wpengine/github-action-wpe-site-deploy](https://github.com/wpengine/github-action-wpe-site-deploy) GitHub Action and the [azunigawpe/wpe-bb-deploy](https://bitbucket.org/azunigawpe/wpe-bb-deploy/src/main/) BitBucket Pipeline. Any customizations to the image should consider the effect on both services.

Any other customizations that are uniquely required can be added to the Dockerfile in the project itself.

## Updating the Docker Image

### Automatic Builds

Docker images are built and pushed automatically:

| Trigger | Tags Updated | Source |
|---------|--------------|--------|
| Push to `main` | `latest` | Docker Hub Autobuild |
| New version release | `latest`, `vX`, `vX.Y`, `vX.Y.Z` | Docker Hub Autobuild |
| Monthly schedule (1st of month) | `latest`, `vX`, `vX.Y`, `vX.Y.Z` | GitHub Actions |

The scheduled monthly rebuild ensures security patches are applied even when there are no new releases. This workflow uses `no-cache` to pull fresh base image layers.

### Base Image Maintenance

The Dockerfile uses Alpine Linux as its base image. The base image follows this update pattern:

- **Dependabot** monitors for new Alpine versions and creates PRs automatically
- **Scheduled rebuilds** pick up security patches from `apk upgrade` monthly
- Alpine releases new versions every 6 months (roughly June and December)

When Dependabot opens a PR for a new Alpine version:

1. Review the [Alpine release notes](https://alpinelinux.org/releases/) for breaking changes
2. Add a changeset to the PR (`npx changeset`) so a proper release is created when merged
3. Merge the PR to trigger a new versioned release

### Docker Hub

Images are published to DockerHub: [wpengine/site-deploy](https://hub.docker.com/r/wpengine/site-deploy)

## Manually updating the Docker Image

You can also build and version this image using make targets when necessary.

```
make build       # Builds the image locally
make version     # Builds the image and creates version tags
make list-images # Shows all tagged versions of the image
make clean       # Deletes all tagged versions of the image
```

To push a custom version of the image to DockerHub:
`docker push wpengine/site-deploy:{tagName}`
