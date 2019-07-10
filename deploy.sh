#!/usr/bin/env bash
set -xv
VM_NAME="python-flask-docker"
FIREWALL_NAME="http-server" 
echo $GCLOUD_SERVICE_KEY | gcloud auth activate-service-account --key-file=-
gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
checkVmExist=$(gcloud compute instances list --filter=name:"${VM_NAME}")
#gcloud compute firewall-rules create circleci-allow-http --target-tags http-server --allow tcp:8080
if [[ ${checkVmExist} == *"${VM_NAME}"* ]]
then
   gcloud compute --quiet instances delete ${VM_NAME} --zone ${GOOGLE_COMPUTE_ZONE}
fi
gcloud compute --quiet instances create-with-container ${VM_NAME} --tags ${FIREWALL_NAME} --zone ${GOOGLE_COMPUTE_ZONE} --container-image daisy200029/$IMAGE_NAME:$TAG
