resource "aws_route53_zone" "app_dns_zone" {
  name = "nationalarchives.gov.uk"
}

resource "aws_route53_record" "tna_ns" {
  allow_overwrite = true
  name            = "nationalarchives.gov.uk."
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.app_dns_zone.zone_id

  records = [
    "ns-1635.awsdns-12.co.uk.",
    "ns-683.awsdns-21.net.",
    "ns-72.awsdns-09.com.",
    "ns-1435.awsdns-51.org."
  ]
}

resource "aws_route53_record" "tna_soa" {
  allow_overwrite = true
  name            = "nationalarchives.gov.uk."
  ttl             = 900
  type            = "SOA"
  zone_id         = aws_route53_zone.app_dns_zone.zone_id

  records = [
    "ns-331.awsdns-41.com. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  ]
}

resource "aws_route53_record" "dns" {
  zone_id = aws_route53_zone.app_dns_zone.zone_id
  name    = "tdr-transfer-jenkins.nationalarchives.gov.uk"
  type    = "A"

  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = false
  }
}