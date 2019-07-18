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
    ## Create new template
   gcloud compute instance-templates create-with-container ${GVM_TEMPLATE_NAME}-${count} \
     --container-image ${DOCKER_LOGIN}/${IMAGE_NAME}:${IMAGE_TAG} \
     --tags http-server
    ## Start rolling update
   gcloud compute instance-groups managed rolling-action start-update ${GVM_NAME} \
    --version template=${GVM_TEMPLATE_NAME}-${count} --zone ${GOOGLE_COMPUTE_ZONE}
else
    ## 1. Create instance template from a container image
    gcloud compute instance-templates create-with-container ${GVM_TEMPLATE_NAME}-${count} \
        --container-image ${DOCKER_LOGIN}/${IMAGE_NAME}:${IMAGE_TAG} \
        --tags http-server 
        

    ## 2. Create manageed instance group and set template, it will take
    gcloud compute instance-groups managed create ${GVM_NAME} \
        --template ${GVM_TEMPLATE_NAME}-${count} \
        --zone ${GOOGLE_COMPUTE_ZONE} \
        --size ${INIT_NUMNER_OF_VM} \
        --http-health-check basic-check

    ## 3. Enable autoscaling 
    gcloud compute instance-groups managed set-autoscaling ${GVM_NAME} \
        --max-num-replicas 20 \
        --target-cpu-utilization 0.75 \
        --cool-down-period 90 \
        --zone ${GOOGLE_COMPUTE_ZONE}

    ## 4. health check on instance group
    gcloud compute instance-groups managed update ${GVM_NAME} \
        --http-health-check basic-check \
        --initial-delay 300 \
        --zone ${GOOGLE_COMPUTE_ZONE}

    ## 5. create a target pool for load balance purpose
    gcloud compute target-pools create ${GVM_LOAD_BALANCER_NAME} \
        --region ${GOOGLE_COMPUTE_ZONE} \
        --http-health-check basic-check

    ## 6. set target group to instance group
    gcloud compute instance-groups managed set-target-pools ${GVM_NAME} \
        --target-pools ${GVM_LOAD_BALANCER_NAME} \
        --zone ${GOOGLE_COMPUTE_ZONE}

    ## 7. frontend forwarding rule
    gcloud compute forwarding-rules create ${GVM_LOAD_BALANCER_FORWARDING_RULE} \
        --region ${GOOGLE_COMPUTE_ZONE} \
        --ports 8080 \
        --address ${STATIC_ADDRESS} \
        --target-pool ${GVM_LOAD_BALANCER_NAME}
fi
 