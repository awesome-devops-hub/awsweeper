# AWSweeper

AWSweeper is based on the cloud-agnostic Terraform API for deletion that wipes out all (or parts) of the resources in your AWS account. Resources to be deleted can be filtered by their ID, tags or
creation date using [regular expressions](https://golang.org/pkg/regexp/syntax/) declared in a yaml file (see [config.yml](example/config.yml)).

Happy erasing!

[![AWSweeper tutorial](img/asciinema-tutorial.gif)](https://asciinema.org/a/149097)

## Usage

- Authenticate your SAML Identity Provider

  More details: https://gitlab.com/tw-toc/saml-aws-functions

- Setup awsweeper latest version v0.6.0:

  ```bash
  # install it into ./bin/
  sh ./install.sh v0.6.0
  ```

- Run the CMD awsweeper

  ```bash
  ./bin/awsweeper [options] <config.yml>
  ```

  For example:
  ```bash
  $ ./bin/awsweeper --region ap-southeast-1 --dry-run example/aws_vpc.yml
   • downloaded and installed provider                  name=aws version=2.43.0
   • configured provider                                name=aws version=2.43.0
   • using region: ap-southeast-1
   • SHOWING RESOURCES THAT WOULD BE DELETED (DRY RUN)

	---
	Type: aws_vpc
	Found: 1

		Id:		vpc-2afc2e4f
		Tags:		[Name: default]

	---

   • TOTAL NUMBER OF RESOURCES THAT WOULD BE DELETED: 1
  ```
  
  To see options available run `./bin/awsweeper --help`.
  
  **Please make sure to add `--dry-run` in each execution for the rehearsal before sweeping any resources**

- Deploy `awsweeper` via AWS Lambda

  To houseclean any irrelevant aws resources in our account, we can simply wrap up `awsweeper` into a python Lambda function, and trigger it periodically as every day at 19:00 UTC `cron(0 19 * * ? *)`, so as to let Lambda take care of every cleanup instead of human hand.

  The deployment will compile and upload all the artefacts into S3 bucket which would be applied by Lambda `awsweeper` CMD execution.

  Here is how to release and deploy Lambda:

  ```bash
  auto/deploy-lambda
  ```

  Here are the detailed params of Lambda in [awsweeper-params.yml](aws/lambda/awsweeper-params.yml)

  ```yml
    ---
    LambdaFunctionS3Bucket: "awsweeper-artefact-bucket"
    LambdaFunctionS3Key: "lambda/awsweeper.zip"
    LambdaFunctionName: "awsweeper"
    LambdaExecutionSchedule: "cron(0 19 * * ? *)"
    VpcId: "vpc-xxxxxxxxxxx"
    SubnetIds: "subnet-xxxxxxxxxx"
    LambdaMemorySize: "256"
    LambdaRuntime: "python3.8"
    LambdaTimeout: "300"
  ```

## Dry-run mode

 Use `./bin/awsweeper --dry-run <config.yml>` to only show what
would be deleted. This way, you can fine-tune your yaml configuration until it works the way you want it to.


## Filtering

Resources to be deleted are filtered by a yaml configuration. To learn how, have a look at the following example:

    aws_instance:
      - id: ^foo.*
        tags:
          foo: bar
          bla: blub
        created:
          before: 2018-06-14
          after: 2018-10-28 12:28:39.0000
      - tags:
          foo: bar
         created:
           before: 2018-06-14
      - tags:
          foo: NOT(bar)
        created:
          after: 2018-06-14
    aws_iam_role:

This config would delete all instances which ID matches `^foo.*` *AND* which have tags `foo: bar` *AND* `bla: blub`
*AND* which have been created between `2018-10-28 12:28:39 +0000 UTC` and `2018-06-14`. Additionally, it would delete instances
with tag `foo: bar` and which are older than `2018-06-14`.

Furthermore, this config would delete all IAM roles, as there is no list of filters provided for this resource type.

The general syntax of the filter config is as follows:

    <resource type>:
      # filter 1
      - id: <regex to filter by id> | NOT(<regex to filter by id>)
        tags:
          <key>: <regex to filter value> | NOT(<regex to filter value>)
          ...
        created:
          before: <timestamp> (optional)
          after: <timestamp> (optional)
      # filter 2
      - ...
    <resource type>:
      ...

A more detailed description of the ways to filter resources:

##### 1) All resources of a particular type

   [Terraform types](https://www.terraform.io/docs/providers/aws/index.html) are used to identify resources of a particular type
   (e.g., `aws_security_group` selects all resources that are security groups, `aws_iam_role` all roles,
   or `aws_instance` all EC2 instances).

   In the example above, by simply adding `security_group:` (no further filters for IDs or tags),
   all security groups in your account would be deleted. Use the [all.yml](./all.yml), to delete all (currently supported)
   resources.

##### 2) By tags

   You can narrow down on particular types of resources by the tags they have.

   If most of your resources have tags, this is probably the best to filter them
   for deletion. But be aware: not all resources support tags and can be filtered this way.

   In the example above, all EC2 instances are terminated that have a tag with key `foo` and value `bar` as well as
   `bla` and value `blub`.
   
   The tag filter can be negated by surrounding the regex with `NOT(...)`

##### 3) By ID

   You can narrow down on particular types of resources by filtering on their IDs.

   To see what the IDs of your resources are (could be their name, ARN, a random number),
   run awsweeper in dry-run mode: `./bin/awsweeper --dry-run all.yml`. This way, nothing is deleted but
   all the IDs and tags of your resources are printed. Then, use this information to create the yaml file.

   In the example above, all roles which name starts with `foo` are deleted (the ID of roles is their name).

   The id filter can be negated by surrounding the regex with `NOT(...)`

##### 4) By creation date

   You can select resources by filtering on the date they have been created using an absolute or relative date.

   The supported formats are:
   * Relative
     * Nanosecond: `1ns`
     * Microsecond: `1us`
     * Millisecond: `1ms`
     * Second: `1s`
     * Minute: `1m`
     * Hour: `1h`
     * Day: `1d`
     * Week: `1w`
     * Month: `1M`
     * Year: `1y`
   * Absolute:
     * RCF3339Nano, short dates: `2006-1-2T15:4:5.999999999Z07:00`
     * RFC3339Nano, short date, lower-case "t": `2006-1-2t15:4:5.999999999Z07:00`
     * Space separated, no time zone: `2006-1-2 15:4:5.999999999`
     * Date only: `2006-1-2`

## Supported resources

AWSweeper can currently delete more than 30 AWS resource types.

Note that the resource types in the list below are [Terraform Types](https://www.terraform.io/docs/providers/aws/index.html),
which must be used in the YAML configuration to filter resources.
A technical reason for this is that AWSweeper is build upon the already existing delete routines provided by the [Terraform AWS provider](https://github.com/terraform-providers/terraform-provider-aws).

| Resource Type                    | Delete by tag | Delete by creation date
| :-----------------------------   |:-------------:|:-----------------------:
| aws_ami                          | x             | x
| aws_autoscaling_group            | x             | x
| aws_cloudformation_stack         | x             | x
| aws_cloudwatch_log_group (*new*) |               | x
| aws_ebs_snapshot                 | x             | x
| aws_ebs_volume                   | x             | x
| aws_ecs_cluster (*new*)          | x             |
| aws_efs_file_system              | x             | x
| aws_eip                          | x             |
| aws_elb                          | x             | x
| aws_iam_group                    | x             | x
| aws_iam_instance_profile         |               | x
| aws_iam_policy                   |               | x
| aws_iam_role                     | x             | x
| aws_iam_user                     | x             | x
| aws_instance                     | x             | x
| aws_internet_gateway             | x             |
| aws_key_pair                     | x             |
| aws_kms_alias                    |               |
| aws_kms_key                      |               |
| aws_lambda_function (*new*)      |               |
| aws_launch_configuration         |               | x
| aws_nat_gateway                  | x             |
| aws_network_acl                  | x             |
| aws_network_interface            | x             |
| aws_rds_instance (*new*)         |               | x
| aws_route53_zone                 |               |
| aws_route_table                  | x             |
| aws_s3_bucket                    |               | x
| aws_security_group               | x             |
| aws_subnet                       | x             |
| aws_vpc                          | x             |
| aws_vpc_endpoint                 | x             | x
   
## Acceptance tests

***WARNING:*** Acceptance tests create real resources that might cost you money.

Run all acceptance tests with

    make testacc

or use

    make testacc TESTARGS='-run=TestAccVpc*'

to test the working of AWSweeper for a just single resource, such as `aws_vpc`.

## Disclaimer

This tool is thoroughly tested. However, you are using this tool at your own risk!
I will not take responsibility if you delete any critical resources in your
production environments.
