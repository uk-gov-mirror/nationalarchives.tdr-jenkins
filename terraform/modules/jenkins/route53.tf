data "aws_route53_zone" "app_dns_zone" {
  name = var.dns_zone
}

resource "aws_route53_record" "dns" {
  zone_id = data.aws_route53_zone.app_dns_zone.zone_id
  name    = "jenkins"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}