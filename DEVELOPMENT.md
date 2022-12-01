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

The `latest` Docker Image will be updated automatically after merging into the `main` branch.
`wpengine/site-deploy:latest`


A versioned Docker Image will be automatically generated for each release of this repository, based on the tag name
`wpengine/site-deploy:{tagName}`

Additional Docker Images will be automatically generated for each branch to use in testing.
`wpengine/site-deploy:branch-{branchName}`

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
