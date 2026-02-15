# ========================================
# ALB for Gateway (Public-facing)
# ========================================

resource "aws_lb" "gateway" {
  count = var.create_alb ? 1 : 0

  name               = "${var.environment}-gateway-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gateway_alb[0].id]
  subnets            = var.subnet_ids

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, {
    Name = "${var.environment}-gateway-alb"
  })
}

# Target group for Gateway workers (HTTPS 443)
resource "aws_lb_target_group" "gateway_https" {
  count = var.create_alb ? 1 : 0

  name        = "${var.environment}-gateway-https-tg"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-399"
    protocol            = "HTTPS"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-gateway-https-tg"
  })
}

# Listener for HTTPS (optional, requires certificate)
# Uncomment and add certificate ARN when ready
# resource "aws_lb_listener" "gateway_https" {
#   load_balancer_arn = aws_lb.gateway.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.gateway_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.gateway_https.arn
#   }
# }

# Security group for Gateway ALB
resource "aws_security_group" "gateway_alb" {
  count = var.create_alb ? 1 : 0

  name        = "${var.environment}-gateway-alb-sg"
  description = "Security group for Gateway ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.environment}-gateway-alb-sg"
  })
}

# Allow HTTPS from internet (for future use)
resource "aws_security_group_rule" "gateway_alb_https" {
  count = var.create_alb ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gateway_alb[0].id
  description       = "Allow HTTPS from internet"
}

# Allow Gateway ALB outbound to workers
resource "aws_security_group_rule" "gateway_alb_egress" {
  count = var.create_alb ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gateway_alb[0].id
  description       = "Allow all outbound traffic"
}

# ========================================
# NLB for Kubernetes API Server
# ========================================

resource "aws_lb" "api_server" {
  count = var.create_nlb ? 1 : 0

  name               = "${var.environment}-apiserver-nlb"
  internal           = false # Set to true for internal-only access; false allows public access
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, {
    Name = "${var.environment}-apiserver-nlb"
  })
}

# Target group for API Server (TCP 6443)
resource "aws_lb_target_group" "api_server" {
  count = var.create_nlb ? 1 : 0

  name        = "${var.environment}-apiserver-tg"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-apiserver-tg"
  })
}

# Listener for API Server
resource "aws_lb_listener" "api_server" {
  count = var.create_nlb ? 1 : 0

  load_balancer_arn = aws_lb.api_server[0].arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_server[0].arn
  }
}

# Security group for API Server NLB (optional, for reference)
# NLB doesn't use security groups directly, but we may need SG rules on target nodes
resource "aws_security_group" "api_server_nlb" {
  count = var.create_nlb ? 1 : 0

  name        = "${var.environment}-apiserver-nlb-sg"
  description = "Security group for API Server NLB access"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.environment}-apiserver-nlb-sg"
  })
}

# Allow API Server access from local/trusted networks
resource "aws_security_group_rule" "api_server_access" {
  count = var.create_nlb ? 1 : 0

  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.api_server_allowed_cidrs
  security_group_id = aws_security_group.api_server_nlb[0].id
  description       = "Allow API Server access from trusted networks"
}

# Allow NLB to reach control plane nodes
resource "aws_security_group_rule" "api_server_to_control_plane" {
  count = var.create_nlb ? 1 : 0

  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = var.control_plane_security_group_id
  source_security_group_id = aws_security_group.api_server_nlb[0].id
  description              = "Allow traffic from API Server NLB to control plane"
}

# Allow NLB outbound
resource "aws_security_group_rule" "api_server_nlb_egress" {
  count = var.create_nlb ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.api_server_nlb[0].id
  description       = "Allow all outbound traffic"
}
