#!/usr/bin/env bash
IMAGE_TAG="0.1.${CIRCLE_BUILD_NUM}"
readonly FINAL_TAG="$IMAGE_TAG"
IMAGE_NAME='python-flask-docker'
GITHUB_REPO='daisy200029'
VM_NAME="python-flask-docker"
FIREWALL_NAME="http-server" 