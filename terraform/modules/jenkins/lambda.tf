data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "sg_update_lambda" {
  function_name = "tdr-jenkins-sg-update-${var.environment}"
  runtime = "python3.7"
  handler = "update_security_groups.lambda_handler"
  role = aws_iam_role.sg_update_lambda_role.arn
  timeout = 30 # seconds
  memory_size = 512 # MB
  filename      = "../lambda/function.zip"
  
  tags = merge(
  var.common_tags,
  map(
  "Name", "jenkins-sg-update-check-lambda-${var.environment}",
  )
  )
}

resource "aws_iam_role" "sg_update_lambda_role" {
  name = "jenkins-sg-update_lambda_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.sg_update_assume_role.json
  tags = merge(
  var.common_tags,
  map(
  "Name", "jenkins-sg-update-lambda-iam-role-${var.environment}",
  )
  )
}

data "aws_iam_policy_document" "sg_update_assume_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_lambda_permission" "with_sns" {
  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sg_update_lambda.arn
  principal = "sns.amazonaws.com"
  source_arn = "arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged"
}

resource "aws_iam_policy" "invoke_jenkins_sg_update_role" {
  name   = "invoke-jenkins-sg-update-api-gateway_${var.environment}"
  path   = "/"
  policy = data.aws_iam_policy_document.sg_update_policy.json
}

resource "aws_iam_role_policy_attachment" "invoke_jenkins_sg_update_attach" {
  role       = aws_iam_role.sg_update_lambda_role.name
  policy_arn = aws_iam_policy.invoke_jenkins_sg_update_role.arn
}

data "aws_iam_policy_document" "sg_update_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]

    resources = [
      "*"
    ]
  }

}
