#!/usr/bin/env bash
IMAGE_NAME='python-flask-docker'
GVM_NAME="${IMAGE_NAME}-group"
GVM_TEMPLATE_NAME="${IMAGE_NAME}-template"
FIREWALL_NAME="http-server"
INIT_NUMNER_OF_VM='2'
GVM_LOAD_BALANCER_NAME="$GVM_NAME-lb"
GVM_LOAD_BALANCER_FORWARDING_RULE="$GVM_LOAD_BALANCER_NAMEGVM_NAME-forwarding-rule"
STATIC_ADDRESS="network-lb-ip-commandline"