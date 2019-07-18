#!/usr/bin/env bash
set -xv
((count = CIRCLE_BUILD_NUM - 2))
echo "IMAGE_TAG=0.1.${count}" >> prod.sh
source prod.sh
echo $GCLOUD_SERVICE_KEY | gcloud auth activate-service-account --key-file=-
gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
checkVmExist=$(gcloud compute instance-group managed list --filter=name:"${GVM_NAME}")
# Update or create instance group.
# if instance group name exists, it create template and then rolling update to the instance group
# if instance group name not exists, it create instance group with autoscaler, load balancer
if [[ ${checkVmExist} == *"${GVM_NAME}"* ]]
then
    # create new template
   gcloud compute instance-templates create-with-container ${GVM_TEMPLATE_NAME}-${count} \
     --container-image ${DOCKER_LOGIN}/${IMAGE_NAME}:${IMAGE_TAG} \
     --tags allow-http
   # start rolling update
   gcloud compute instance-groups managed rolling-action start-update ${GVM_NAME} \
    --version template=${GVM_TEMPLATE_NAME}-${count} --zone ${GOOGLE_COMPUTE_ZONE}

fi
   #gcloud compute --quiet instances create-with-container ${VM_NAME} \
   #--tags ${FIREWALL_NAME} --zone ${GOOGLE_COMPUTE_ZONE} \
   #--container-image ${DOCKER_LOGIN}/$IMAGE_NAME:$IMAGE_TAG