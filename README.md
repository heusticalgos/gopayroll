# gopayroll ![Build Status](https://github.com/heusticalgos/gopayroll/workflows/Master%20Deploy/badge.svg)
A demo payroll system written in Go.

## Github Actions
This repository uses [Github Actions](https://github.com/features/actions) as its CI/CD workflow.

## Folder Structure
```
gopayroll/
    ci/
      - CI/CD scripts and github actions
    heustics/ <- GOPATH
        src/
            libs/
                - shared library packages
            services/
                - containerized services for cloud deployment
```

## GOPATH

You may want to setup your GOPATH as follows:

```
  export GOPATH=`pwd`/vendor:`pwd`/heustics
  export GOBIN=`pwd`/vendor/bin
```

The [direnv](https://github.com/direnv/direnv) tool is helpful for managing the GOPATH automatically.

## Dockerhub
On a _push_ to the `master` branch, this repository will build and push all changed images to their respective [Dockerhub registry](https://hub.docker.com/_/registry).

If you clone this repository and wish to continue pushing images to the Dockerhub registry, you will need to ensure the following environment variables are set:

- DOCKER_REGISTRY
  - the Dockerhub registry
- DOCKER_ACCESS_TOKEN
  - the Dockerhub registry access token
- DOCKER_ACCESS_USER
  - the Dockerhub user with permission to collaborate on the associated repository

To push images using Github Actions, you must add these variables as [Secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).
