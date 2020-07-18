#!/bin/bash -eu

cd $(dirname $0)/..

APP_NAME="awsweeper"
TIME_STAMP="$(TZ=Asia/Shanghai date +'%Y%m%d%H%M')"
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
SWEEP_REGION=("ap-northeast-1" "ap-northeast-2" "ap-southeast-1" "ap-southeast-2" "us-east-1" "us-east-2")
AWSWEEPER_LOG="/tmp/awsweeper-${TIME_STAMP}.log"
AWSWEEPER_CFG="./config/aws_resource.yml"
ARTEFACT_BUCKET="${APP_NAME}-artefact-bucket"
AWS_DEFAULT_REGION="ap-northeast-2"
DRY_RUN="-dry-run"
FORCE="-force"

for region in ${SWEEP_REGION[@]}
do
    echo ">>> Start sweeping in $region  <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
    ./bin/awsweeper --region $region ${DRY_RUN} ${AWSWEEPER_CFG} 2>&1 | tee -a ${AWSWEEPER_LOG}
    echo ">>> Finished sweeping in $region <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
done

echo ">>> Sync ${AWSWEEPER_LOG} to S3 bucket ${ARTEFACT_BUCKET}-${AWS_DEFAULT_REGION} <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
echo ">>> Done <<<" 2>&1 | tee -a ${AWSWEEPER_LOG}
aws s3 cp "${AWSWEEPER_LOG}" "s3://${ARTEFACT_BUCKET}-${AWS_DEFAULT_REGION}/log/"

aws autoscaling terminate-instance-in-auto-scaling-group --instance-id "$instance_id" --should-decrement-desired-capacity --region "$AWS_DEFAULT_REGION" | tr '\n' ' ' | xargs -0 echo
