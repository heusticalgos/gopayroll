# gopayroll
A demo payroll system written in Go.

## Github Actions
This repository uses [Github Actions](https://github.com/features/actions) as its CI/CD workflow.

## Dockerhub
On push to the `master` branch, this repository will build and push changed images to the [Dockerhub registry](https://hub.docker.com/_/registry)

If you clone this repository and wish to also push your images to the Dockerhub registry, you will need to ensure the following environment variables are set:

- DOCKER_REGISTRY
  - the Dockerhub repository
- DOCKER_ACCESS_TOKEN
  - the Dockerhub access token
- DOCKER_ACCESS_USER
  - the Dockerhub user with permission to push to the repository

Using Github Actions, you can add this variables as [Secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).
