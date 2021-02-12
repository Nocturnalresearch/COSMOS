#!/usr/bin/env bash

usage() {
  echo "Usage: $1 [setup, start, stop, cleanup, build, deploy, start_dev]" >&2
  echo "*  setup: setup containers to build and run" >&2
  echo "*  start: start the minimal docker run for cosmos" >&2
  echo "*  stop: stop the running dockers for cosmos" >&2
  echo "*  cleanup: cleanup network and volumes for cosmos" >&2
  echo "*  build: build the containers for cosmos" >&2
  echo "*  deploy: deploy the containers to localhost repository" >&2
  echo "*  start_dev: start all dockers for cosmos" >&2
  exit 1
}

if [ $# -ne 1 ]; then
  usage $0
fi

case $1 in
start)
  scripts/linux/cosmos_setup.sh
  scripts/linux/cosmos_minimal_start.sh
  ;;
start_dev)
  scripts/linux/cosmos_setup.sh
  scripts/linux/cosmos_start.sh
  ;;
stop)
  scripts/linux/cosmos_stop.sh
  ;;
build)
  scripts/linux/cosmos_setup.sh
  scripts/linux/cosmos_build.sh
  ;;
cleanup)
  scripts/linux/cosmos_cleanup.sh
  ;;
deploy)
  scripts/linux/cosmos_deploy.sh
  ;;
setup)
  scripts/linux/cosmos_setup.sh
  ;;
*)
  usage $0
  ;;
esac