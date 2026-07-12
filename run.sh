#!/bin/bash

docker run \
  --security-opt seccomp=unconfined \
  -v $HOME/code/mrpt-salsa:/tmp/mrpt_build \
  -v $HOME/.gitconfig:/home/$(whoami)/.gitconfig:ro \
  -v $HOME/.ssh:/home/$(whoami)/.ssh:ro \
  -e USER=$(whoami) \
  -e HOME=/home/$(whoami) \
  -u $(id -u):$(id -g) \
  -it --rm mrpt_builder
