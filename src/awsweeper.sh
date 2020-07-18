#!/bin/bash -eu

cd $(dirname $0)/..
source ./src/env

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

for region in ${SWEEP_REGION[@]}
do
    echo ">>> Start sweeping in $region  <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
    ./bin/awsweeper --region $region ${!ACTION_MODE} ${AWSWEEPER_CFG} 2>&1 | tee -a ${AWSWEEPER_LOG}
    echo ">>> Finished sweeping in $region <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
done

echo ">>> Done <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
echo ">>> Sync ${AWSWEEPER_LOG} to S3 bucket ${ARTEFACT_BUCKET}-${AWS_DEFAULT_REGION} <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
aws s3 cp "${AWSWEEPER_LOG}" "s3://${ARTEFACT_BUCKET}-${AWS_DEFAULT_REGION}/log/"

aws autoscaling terminate-instance-in-auto-scaling-group --instance-id "$INSTANCE_ID" --should-decrement-desired-capacity --region "$AWS_DEFAULT_REGION" | tr '\n' ' ' | xargs -0 echo
