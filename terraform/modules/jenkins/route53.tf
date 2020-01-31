data "aws_route53_zone" "app_dns_zone" {
  name = "tdr-management.nationalarchives.gov.uk"
}

resource "aws_route53_record" "dns" {
  zone_id = data.aws_route53_zone.app_dns_zone.zone_id
  name    = "jenkins"
  type    = "A"

  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = false
  }
}