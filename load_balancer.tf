resource "aws_lb" "this" {
  name                             = "${var.name}-lb"
  internal                         = false
  load_balancer_type               = "application"
  subnets                          = [for subnet in aws_subnet.this_public : subnet.id]
  security_groups                  = [aws_security_group.this_lb.id]
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields       = true

  tags = {
    Name = "${var.name}_lb"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.name}-lb-target-group"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.this.id
  port             = var.port
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.this.arn
      }

      stickiness {
        duration = 1
      }
    }
  }
}

resource "aws_security_group" "this_lb" {
  name   = "${var.name}-lb-security-group"
  vpc_id = aws_vpc.this.id

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
    Name = "${var.name}_lb_security_group"
  }
}