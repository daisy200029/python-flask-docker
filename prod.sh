#!/usr/bin/env bash
IMAGE_NAME='python-flask-docker'
GMGI_NAME="${IMAGE_NAME}-group"
GMGI_TEMPLATE_NAME="${IMAGE_NAME}-template"
FIREWALL_NAME="http-server"
INIT_NUMNER_OF_VM='2'
GMGI_LOAD_BALANCER_NAME="$GVM_NAME-lb"
GMGI_LOAD_BALANCER_FORWARDING_RULE="$GVM_LOAD_BALANCER_NAMEGVM_NAME-forwarding-rule"
STATIC_ADDRESS="network-lb-ip-commandline"
HEALTH_CHECK_NAME="basic-check"
