resource "aws_lb" "this" {
  count = var.enable_load_balancer ? 1 : 0

  name                             = "${var.name_prefix}-lb"
  internal                         = false
  load_balancer_type               = "application"
  subnets                          = data.aws_subnets.public.ids
  security_groups                  = [aws_security_group.lb[0].id]
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields       = true

  tags = {
    Name = "${var.name_prefix}_lb"
  }
}

resource "aws_lb_target_group" "this" {
  count = var.enable_load_balancer ? 1 : 0

  name     = "${var.name_prefix}-lb-target-group"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.enable_load_balancer ? 1 : 0

  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = aws_instance.this.id
  port             = var.port
}

resource "aws_lb_listener" "this" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.this[0].arn
      }

      stickiness {
        duration = 1
      }
    }
  }
}

resource "aws_security_group" "lb" {
  count = var.enable_load_balancer ? 1 : 0

  name   = "${var.name_prefix}-lb-security-group"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  tags = {
    Name = "${var.name_prefix}_lb_security_group"
  }
}
