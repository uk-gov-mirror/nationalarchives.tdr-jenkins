data "aws_ip_ranges" "cloudfront_ranges_global" {
  regions  = ["global"]
  services = ["cloudfront"]
}

data "aws_ip_ranges" "cloudfront_ranges_regional" {
  regions  = ["ap-northeast-1","ap-northeast-2","ap-south-1","ap-southeast-1","ap-southeast-2","ca-central-1","eu-central-1","eu-west-2","eu-west-2","eu-west-3","sa-east-1","us-east-1","us-east-2","us-west-1","us-west-2"]
  services = ["cloudfront"]
}

resource "aws_security_group" "ec2_internal" {
  name = "${var.app_name}-ec2-security-group-internal"
  description = "Controls access within our network for Jenkins"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    #"${aws_security_group.example.*.id}"
    cidr_blocks = [
    for num in aws_eip.gw[*].public_ip:
      cidrsubnet("${num}/32", 0, 0)
    ]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # 50000 is the port which allows the nodes to connect to the parent
  ingress {
    protocol    = "tcp"
    from_port   = 50000
    to_port     = 50000
    cidr_blocks = [
    for num in aws_eip.gw[*].public_ip:
    cidrsubnet("${num}/32", 0, 0)
    ]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 50000
    to_port     = 50000
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_cloudfront_global" {
  name        = "${var.app_name}-ec2-security-group-global"
  description = "Allows access to Jenkins from global cloudfront IPs"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks      = data.aws_ip_ranges.cloudfront_ranges_global.cidr_blocks
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
  var.common_tags,
  map("Name", "${var.app_name}-ec2-security-group-global-${var.environment}", "Type", "Jenkins Cloudfront", "Range", "Global")
  )
}

resource "aws_security_group" "ec2_cloudfront_regional" {
  name        = "${var.app_name}-ec2-security-group-regional"
  description = "Allows access to Jenkins from regional cloudfront IPs"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = data.aws_ip_ranges.cloudfront_ranges_regional.cidr_blocks
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
  var.common_tags,
  map("Name", "${var.app_name}-load-balancer-security-group-${var.environment}", "Type", "Jenkins Cloudfront", "Range", "Regional")
  )
}


resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-ecs-tasks-security-group"
  description = "Allow outbound access only"
  vpc_id      = aws_vpc.main.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    map("Name", "${var.environment}-ecs-task-security-group")
  )
}

