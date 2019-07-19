#!/usr/bin/env bash
set -xv
# decrease 2 of build number to reference the image tag number
((count = CIRCLE_BUILD_NUM - 2))
echo -e "IMAGE_TAG=0.1.${count}" >> prod.sh
# Apply variables 
source prod.sh
echo $GCLOUD_SERVICE_KEY | gcloud auth activate-service-account --key-file=-
# Set gcloud login information
gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
# check if instance group exists
checkVmExist=$(gcloud compute instance-groups managed list --filter=name:"${GMGI_NAME}")
# Update or create instance group.If instance group name exists, it create template and then 
# rolling update to the instance group. If instance group name not exists, it create 
# instance group with autoscaler, load balancer
if [[ ${checkVmExist} == *"${GMGI_NAME}"* ]]
then
    ## 1. Create new instance template
    gcloud compute instance-templates create-with-container ${GMGI_TEMPLATE_NAME}-${count} \
     --container-image ${DOCKER_LOGIN}/${IMAGE_NAME}:${IMAGE_TAG} \
     --tags http-server
    ## 2. Start rolling update to instance group
    gcloud compute instance-groups managed rolling-action start-update ${GMGI_NAME} \
    --version template=${GMGI_TEMPLATE_NAME}-${count} --zone ${GOOGLE_COMPUTE_ZONE}
else
    ## 1. Create instance template from a container image
    gcloud compute instance-templates create-with-container ${GMGI_TEMPLATE_NAME}-${count} \
        --container-image ${DOCKER_LOGIN}/${IMAGE_NAME}:${IMAGE_TAG} \
        --tags http-server 
        

    ## 2. Create manageed instance group and set template
    gcloud compute instance-groups managed create ${GMGI_NAME} \
        --template ${GMGI_TEMPLATE_NAME}-${count} \
        --zone ${GOOGLE_COMPUTE_ZONE} \
        --size ${INIT_NUMNER_OF_VM} \
        --http-health-check ${HEALTH_CHECK_NAME}

    ## 3. Enable autoscaling 
    gcloud compute instance-groups managed set-autoscaling ${GMGI_NAME} \
        --max-num-replicas 20 \
        --target-cpu-utilization 0.75 \
        --cool-down-period 90 \
        --zone ${GOOGLE_COMPUTE_ZONE}

    ## 4. Apply health check on instance group
    gcloud compute instance-groups managed update ${GMGI_NAME} \
        --http-health-check basic-check \
        --initial-delay 300 \
        --zone ${GOOGLE_COMPUTE_ZONE}

    ## 5. Create a target pool for load balance purpose
    gcloud compute target-pools create ${GMGI_LOAD_BALANCER_NAME} \
        --region ${GOOGLE_COMPUTE_REGION} \
        --http-health-check ${HEALTH_CHECK_NAME}

    ## 6. Set target pool to instance group
    gcloud compute instance-groups managed set-target-pools ${GMGI_NAME} \
        --target-pools ${GMGI_LOAD_BALANCER_NAME} \
        --zone ${GOOGLE_COMPUTE_ZONE}

    ## 7. Set Frontend forwarding rule to taget pool
    gcloud compute forwarding-rules create ${GMGI_LOAD_BALANCER_FORWARDING_RULE} \
        --region ${GOOGLE_COMPUTE_ZONE} \
        --ports 8080 \
        --address ${STATIC_ADDRESS} \
        --target-pool ${GMGI_LOAD_BALANCER_NAME}
fi
 