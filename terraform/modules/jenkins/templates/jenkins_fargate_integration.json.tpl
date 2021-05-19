{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:ListBucket",
        "s3:GetObject",
        "iam:PassRole",
        "ecs:StopTask",
        "ecs:RunTask",
        "ecs:ListContainerInstances",
        "ecs:DescribeTasks"
      ],
      "Resource": [
        "arn:aws:s3:::tdr-staging-mgmt/*",
        "arn:aws:s3:::tdr-staging-mgmt",
        "arn:aws:s3:::tdr-releases-mgmt/*",
        "arn:aws:s3:::tdr-releases-mgmt",
        "arn:aws:iam::${account_id}:role/TDRTerraformRoleMgmt",
        "arn:aws:iam::${account_id}:role/TDRTerraformAssumeRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRTerraformAssumeRoleProd",
        "arn:aws:iam::${account_id}:role/TDRTerraformAssumeRoleIntg",
        "arn:aws:iam::${account_id}:role/TDRScriptsTerraformRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRScriptsTerraformRoleProd",
        "arn:aws:iam::${account_id}:role/TDRScriptsTerraformRoleIntg",
        "arn:aws:iam::${account_id}:role/TDRJenkinsRunSsmRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRJenkinsRunSsmRoleProd",
        "arn:aws:iam::${account_id}:role/TDRJenkinsRunSsmRoleIntg",
        "arn:aws:iam::${account_id}:role/TDRJenkinsPublishRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeS3ExportRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeS3ExportRoleIntg",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeRoleProd",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeRoleIntg",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeReadParamsRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeReadParamsRoleProd",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeReadParamsRoleIntg",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeLambdaRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeLambdaRoleProd",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeLambdaRoleMgmt",
        "arn:aws:iam::${account_id}:role/TDRJenkinsNodeLambdaRoleIntg",
        "arn:aws:iam::${account_id}:role/TDRJenkinsCheckAmiRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsBuildTransferFrontendExecutionRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsBuildTerraformExecutionRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsBuildPostgresExecutionRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsBuildPluginUpdatesExecutionRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsBuildNpmExecutionRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsBuildAwsExecutionRole",
        "arn:aws:iam::${account_id}:role/TDRJenkinsAppTaskRoleMgmt",
        "arn:aws:iam::${account_id}:role/TDRJenkinsAppExecutionRoleMgmt",
        "arn:aws:iam::${account_id}:role/TDRCustodianAssumeRoleStaging",
        "arn:aws:iam::${account_id}:role/TDRCustodianAssumeRoleProd",
        "arn:aws:iam::${account_id}:role/TDRCustodianAssumeRoleIntg",
        "arn:aws:ecs:eu-west-2:${account_id}:task/*",
        "arn:aws:ecs:eu-west-2:${account_id}:task-definition/*:*",
        "arn:aws:ecs:eu-west-2:${account_id}:cluster/jenkins-mgmt"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream",
        "ecs:RegisterTaskDefinition",
        "ecs:ListTaskDefinitions",
        "ecs:ListClusters",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeContainerInstances",
        "ecs:DeregisterTaskDefinition"
      ],
      "Resource": "*"
    }
  ]
}