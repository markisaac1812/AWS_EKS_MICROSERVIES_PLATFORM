############################################
# Network Load Balancer
#
# Fronts the EKS cluster's ingress layer. In production the NLB itself
# is typically provisioned dynamically by the AWS Load Balancer
# Controller (see eks_addons.tf) whenever a Kubernetes Service of
# type LoadBalancer / Ingress with the "nlb-ip" target-type annotation
# is created, since target registration must track pod IPs as they
# change. The static aws_lb resource below is kept for scenarios where
# a pre-provisioned, Terraform-managed NLB is required (e.g. a shared
# ingress-nginx controller) and is left with an empty target group that
# the ingress controller / LB controller can adopt via annotations.
############################################

resource "aws_lb" "main" {
  name               = "${local.name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  tags = merge(local.common_tags, { Name = "${local.name}-nlb" })
}

resource "aws_lb_target_group" "http" {
  name        = "${local.name}-tg-http"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    healthy_threshold    = 3
    unhealthy_threshold  = 3
    interval             = 10
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_target_group" "https" {
  name        = "${local.name}-tg-https"
  port        = 443
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    healthy_threshold    = 3
    unhealthy_threshold  = 3
    interval             = 10
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}
