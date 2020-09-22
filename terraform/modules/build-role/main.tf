resource "aws_iam_role" "jenkins_build_role" {
  name               = "${local.name}ExecutionRole"
  assume_role_policy = templatefile("${path.module}/templates/assume_role_policy.json.tpl", {})
  tags               = { "Name" = "${local.name}ExecutionRole" }
}

resource "aws_iam_policy" "jenkins_build_policy" {
  policy = templatefile("${path.module}/templates/build_policy.json.tpl", { repository_arn = var.repository_arn })
  name   = "${local.name}ExecutionPolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_build_role_policy" {
  policy_arn = aws_iam_policy.jenkins_build_policy.arn
  role       = aws_iam_role.jenkins_build_role.name
}
