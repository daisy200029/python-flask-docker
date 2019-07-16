#!/usr/bin/env bash
set -xv
source staging.sh
echo $GCLOUD_SERVICE_KEY | gcloud auth activate-service-account --key-file=-
gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
checkVmExist=$(gcloud compute instances list --filter=name:"${VM_NAME}")
# given firewall exits, 
# (gcloud compute firewall-rules create http-server --target-tags http-server --allow tcp:8080)
# if vm name exists, it updated image on the vm
# if vm name not exists, it creates vm with image
if [[ ${checkVmExist} == *"${VM_NAME}"* ]]
then
   gcloud compute --quiet instances update-container ${VM_NAME} --zone ${GOOGLE_COMPUTE_ZONE} --container-image daisy200029/$IMAGE_NAME:$IMAGE_TAG
else
   gcloud compute --quiet instances create-with-container ${VM_NAME} --tags ${FIREWALL_NAME} --zone ${GOOGLE_COMPUTE_ZONE} --container-image daisy200029/$IMAGE_NAME:$IMAGE_TAG
fi