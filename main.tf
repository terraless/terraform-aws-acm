resource "aws_acm_certificate" "this" {
  count = var.create_certificate

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

//data "aws_acm_certificate" "this" {
//  count = "${1 - var.create_certificate}"
//
//  domain = "${var.domain_name}"
//
//  types = ["${var.acm_certificate_types}"]
//  statuses = ["${var.acm_certificate_statuses}"]
//  most_recent = "${var.acm_certificate_most_recent}"
//}

resource "aws_route53_record" "validation" {
  count = var.create_certificate && var.validation_method == "DNS" && var.validate_certificate ? length(var.subject_alternative_names) + 1 : 0

  zone_id = var.zone_id
  name    = aws_acm_certificate.this.0.domain_validation_options[count.index]["resource_record_name"]
  type    = aws_acm_certificate.this.0.domain_validation_options[count.index]["resource_record_type"]
  ttl     = 60

  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  records = [
    aws_acm_certificate.this.0.domain_validation_options[count.index]["resource_record_value"],
  ]
}

resource "aws_acm_certificate_validation" "this" {
  count = var.create_certificate && var.validation_method == "DNS" && var.validate_certificate && var.wait_for_validation ? 1 : 0

  certificate_arn = aws_acm_certificate.this[0].arn

  validation_record_fqdns = aws_route53_record.validation.*.fqdn
}

