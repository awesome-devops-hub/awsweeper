import subprocess
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    CMD1=["cp", "-a", "bin", "config", "/tmp"]
    subprocess.run(CMD1)

    os.chdir("/tmp")

    CMD2=["./bin/awsweeper", "--region", "ap-southeast-1", "--dry-run", "./config/aws_security_group.yml"]
    output2 = subprocess.check_output(CMD2, universal_newlines=True)
    logger.info(output2)
