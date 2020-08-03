# ------------------------
#  Environment Variables
# ------------------------
# SHARD := ci worker node
# TARGET := make target
#
# Makefile:
# GITHUB_EVENT_PATH := path to Github workflow event.json file
# GITHUB_TOKEN := Github token required to make pull request comments
# DOCKER_REGISTRY := Docker hub registry name
# DOCKER_ACCESS_USERNAME, DOCKER_ACCCESS_TOKEN := Docker access credentials to given DOCKER_REGISTRY

target=$1

dirty_pkgs_file=$HOME/dirty_pkgs-$SHARD.txt
while read pkg; do
    make -C ${pkg} ${target}
done < $dirty_pkgs_file
