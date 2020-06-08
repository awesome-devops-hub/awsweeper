#!/bin/bash -x

cd $(dirname $0)/..

APP_NAME="awsweeper"
TIME_STAMP="$(TZ=Singapore date +'%Y%m%d%H%M')"
SWEEP_REGION=("ap-northeast-1" "ap-northeast-2" "ap-southeast-1" "ap-southeast-2")
AWSWEEPER_LOG="/tmp/awsweeper-${TIME_STAMP}.log"
ARTEFACT_BUCKET="${APP_NAME}-artefact-bucket"
AWS_DEFAULT_REGION="ap-northeast-2"
DRY_RUN="-dry-run"
FORCE="-force"

for host in ${SWEEP_REGION[@]}
do
    ./bin/awsweeper --region $host ${DRY_RUN} ./config/aws_resource.yml 2>&1 | tee -a ${AWSWEEPER_LOG}
done

aws s3 cp "${AWSWEEPER_LOG}" "s3://${ARTEFACT_BUCKET}-${AWS_DEFAULT_REGION}/log/"
