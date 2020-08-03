include makefile.defs

# ------------------------
#  Environment Variables
# ------------------------
# NUM_SHARDS := max number of shards (parallel nodes) that executing actions on dirty packages
NUM_SHARDS ?= 1


# ------------------------
#  CI Action Targets
# ------------------------

## Find dirty packages that require further actions to be taken, ie. test, build, deploy
dirty_pkgs:
	docker run --rm --name=pkgs-${docker_service_name} \
		-v ${service_mount}:/${repos_name} \
		-v ${HOME}/.gocache:/gocache \
		-v ${HOME}:/github_home \
		-w /${repos_name} \
		-e GOPATH=/${repos_name}/vendor:/${repos_name}/heustics \
		-e GOBIN=/go/bin \
		-e CGO_ENABLED=${cgo_enabled} \
		-e PROJECT_ENV=local \
		-e SECURE_PATH=/dev/null \
		-e CONFIG_PATH=/${repos_name}/testconfig.cfg \
		-e GOCACHE=/gocache/shard${SHARD}/${go_version} \
		-e CI_PATH=/${repos_name}/ci \
		-e GITHUB_HOME=/github_home \
		${builder_image} /bin/sh -c "apt-get update ; \
			apt-get -y install software-properties-common ; \
			apt-get install -y python3.7 ; \
			apt-get install -y python3-pip ; \
			pip3 install -r ci/requirements.txt ; \
			go version ; \
			python3 --version ; \
			python3 /${repos_name}/ci/find_dirty_pkgs.py /github_home ${repos_src_root}/src /${repos_name} ${NUM_SHARDS}"
