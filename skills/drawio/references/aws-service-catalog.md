# AWS Service Catalog

Official service name -> `resIcon` -> category colour. Every `resIcon` here is verified against
draw.io's official shape index; every name is the current official AWS service name.

**Use the name in the first column verbatim as the icon `value`.** Wrap names longer than 18
characters with an explicit `&#xa;` break (see SKILL.md RULE 2).

Style form: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.<resIcon>;` with
`fillColor=<colour>;strokeColor=#ffffff;` — except rows marked neutral, which use
`fillColor=#ffffff;strokeColor=#232F3E;`.

## Compute

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon EC2 | `ec2` | `#ED7100` |
| Amazon ECS | `ecs` | `#ED7100` |
| Amazon EKS | `eks` | `#ED7100` |
| AWS Fargate | `fargate` | `#ED7100` |
| AWS Lambda | `lambda_function` | `#ED7100` |
| Amazon EC2 Auto Scaling | `auto_scaling2` | `#ED7100` |
| AWS Batch | `batch` | `#ED7100` |
| AWS Elastic Beanstalk | `elastic_beanstalk` | `#ED7100` |
| AWS App Runner | `app_runner` | `#ED7100` |
| Amazon Lightsail | `lightsail` | `#ED7100` |
| Amazon ECR | `ecr` | `#ED7100` |

## Storage

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon S3 | `s3` | `#7AA116` |
| Amazon EBS | `elastic_block_store` | `#7AA116` |
| Amazon EFS | `elastic_file_system` | `#7AA116` |
| Amazon S3 Glacier | `glacier` | `#7AA116` |
| AWS Backup | `backup` | `#7AA116` |
| AWS Storage Gateway | `storage_gateway` | `#7AA116` |
| Amazon FSx | `fsx` | `#7AA116` |

## Database

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon RDS | `rds` | `#C925D1` |
| Amazon Aurora | `aurora` | `#C925D1` |
| Amazon DynamoDB | `dynamodb` | `#C925D1` |
| Amazon ElastiCache | `elasticache` | `#C925D1` |
| Amazon Neptune | `neptune` | `#C925D1` |
| Amazon DocumentDB | `documentdb_with_mongodb_compatibility` | `#C925D1` |
| Amazon MemoryDB | `memorydb_for_redis` | `#C925D1` |
| Amazon Timestream | `timestream` | `#C925D1` |

## Networking & Content Delivery

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon VPC | `vpc` | `#8C4FFF` |
| Amazon CloudFront | `cloudfront` | `#8C4FFF` |
| Amazon Route 53 | `route_53` | `#8C4FFF` |
| Elastic Load Balancing | `elastic_load_balancing` | `#8C4FFF` |
| AWS Direct Connect | `direct_connect` | `#8C4FFF` |
| AWS Transit Gateway | `transit_gateway` | `#8C4FFF` |
| AWS Global Accelerator | `global_accelerator` | `#8C4FFF` |
| AWS PrivateLink | `vpc_privatelink` | `#8C4FFF` |
| AWS Cloud Map | `cloud_map` | `#8C4FFF` |
| NAT gateway | `nat_gateway` | `#ffffff` + stroke `#232F3E` |
| internet gateway | `internet_gateway` | `#ffffff` + stroke `#232F3E` |
| VPN gateway | `vpn_gateway` | `#ffffff` + stroke `#232F3E` |
| VPC endpoint | `endpoints` | `#ffffff` + stroke `#232F3E` |

## Security, Identity & Compliance

| Official name | resIcon | fillColor |
|---|---|---|
| AWS IAM | `identity_and_access_management` | `#DD344C` |
| Amazon Cognito | `cognito` | `#DD344C` |
| AWS KMS | `key_management_service` | `#DD344C` |
| AWS WAF | `waf` | `#DD344C` |
| AWS Shield | `shield` | `#DD344C` |
| AWS Secrets Manager | `secrets_manager` | `#DD344C` |
| Amazon GuardDuty | `guardduty` | `#DD344C` |
| AWS Security Hub | `security_hub` | `#DD344C` |
| Amazon Inspector | `inspector` | `#DD344C` |
| Amazon Macie | `macie` | `#DD344C` |
| AWS Certificate Manager | `certificate_manager` | `#ffffff` + stroke `#232F3E` |

## Application Integration

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon SQS | `sqs` | `#E7157B` |
| Amazon SNS | `sns` | `#E7157B` |
| Amazon EventBridge | `eventbridge` | `#E7157B` |
| AWS Step Functions | `step_functions` | `#E7157B` |
| Amazon API Gateway | `api_gateway` | `#E7157B` |
| AWS AppSync | `appsync` | `#E7157B` |
| Amazon MQ | `mq` | `#E7157B` |

## Management & Governance

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon CloudWatch | `cloudwatch_2` | `#E7157B` |
| AWS CloudFormation | `cloudformation` | `#E7157B` |
| AWS CloudTrail | `cloudtrail` | `#E7157B` |
| AWS Systems Manager | `systems_manager` | `#E7157B` |
| AWS Config | `config` | `#E7157B` |
| AWS Organizations | `organizations` | `#E7157B` |
| AWS Control Tower | `control_tower` | `#E7157B` |
| AWS X-Ray | `xray` | `#C925D1` |

## Analytics

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon Kinesis Data Streams | `kinesis_data_streams` | `#8C4FFF` |
| Amazon Data Firehose | `kinesis_data_firehose` | `#8C4FFF` |
| Amazon Athena | `athena` | `#8C4FFF` |
| AWS Glue | `glue` | `#8C4FFF` |
| Amazon EMR | `emr` | `#8C4FFF` |
| Amazon QuickSight | `quicksight` | `#8C4FFF` |
| Amazon OpenSearch Service | `elasticsearch_service` | `#8C4FFF` |
| Amazon MSK | `managed_streaming_for_kafka` | `#8C4FFF` |
| AWS Lake Formation | `lake_formation` | `#8C4FFF` |
| Amazon Redshift | `redshift` | `#8C4FFF` |

## Machine Learning

| Official name | resIcon | fillColor |
|---|---|---|
| Amazon SageMaker AI | `sagemaker` | `#01A88D` |
| Amazon Bedrock | `bedrock` | `#01A88D` |
| Amazon Comprehend | `comprehend` | `#01A88D` |
| Amazon Lex | `lex` | `#01A88D` |
| Amazon Rekognition | `rekognition_2` | `#01A88D` |
| Amazon Textract | `textract` | `#01A88D` |
| Amazon Polly | `polly` | `#01A88D` |
| Amazon Transcribe | `transcribe` | `#01A88D` |
| Amazon Translate | `translate` | `#01A88D` |
| Amazon Kendra | `kendra` | `#01A88D` |

## Developer Tools

| Official name | resIcon | fillColor |
|---|---|---|
| AWS CodePipeline | `codepipeline` | `#C925D1` |
| AWS CodeBuild | `codebuild` | `#C925D1` |
| AWS CodeDeploy | `codedeploy` | `#C925D1` |
| AWS CodeCommit | `codecommit` | `#C925D1` |
| AWS CodeArtifact | `codeartifact` | `#C925D1` |

## External actors (neutral white tile)

| Official name | resIcon | fillColor |
|---|---|---|
| Users | `users` | `#ffffff` + stroke `#232F3E` |
| User | `user` | `#ffffff` + stroke `#232F3E` |
| Client | `client` | `#ffffff` + stroke `#232F3E` |
| Mobile client | `mobile_client` | `#ffffff` + stroke `#232F3E` |
| Internet | `internet` | `#ffffff` + stroke `#232F3E` |
| Corporate data center | `corporate_data_center` | `#ffffff` + stroke `#232F3E` |

## Renamed services — do not use the old name

| Current official name | Former name | Renamed |
|---|---|---|
| Amazon Data Firehose | Amazon Kinesis Data Firehose | Feb 2024 |
| Amazon SageMaker AI | Amazon SageMaker | Dec 2024 |
| Amazon Managed Service for Apache Flink | Amazon Kinesis Data Analytics | Aug 2023 |
| Amazon OpenSearch Service | Amazon Elasticsearch Service | Sep 2021 |

Note: the `resIcon` for Amazon OpenSearch Service is still `elasticsearch_service` and
Amazon Data Firehose is still `kinesis_data_firehose` — draw.io kept the old shape IDs.

## Anything not listed here

Look it up in `valid-aws4-resicons.tsv` (554 entries, tab-separated:
`resIcon`, shape-picker title, official colour). Never guess a name — an invalid
`resIcon` renders as a blank coloured square with no error.

Names are always `snake_case`. Common mistakes: `applicationLoadBalancer` (correct:
`application_load_balancer`, a dedicated shape), `cloudwatch` (correct: `cloudwatch_2`),
`rekognition` (prefer `rekognition_2`).
