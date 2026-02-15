data "aws_ami" "image" {
  most_recent = true
  owners      = [var.ami_owner] # Amazon owner

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "main" {
  for_each = length(keys(var.instances)) > 0 ? var.instances : tomap({ for idx in range(var.instance_count) : "instance-${idx}" => {
    subnet_id           = element(var.subnet_id, idx % length(var.subnet_id))
    associate_public_ip = length(var.associate_public_ip) > 0 ? element(var.associate_public_ip, idx) : false
    instance_type       = var.instance_type
    index               = idx
  } })

  ami           = data.aws_ami.image.id
  instance_type = lookup(each.value, "instance_type", var.instance_type)

  # Spot instance configuration
  dynamic "instance_market_options" {
    for_each = lookup(each.value, "use_spot", false) ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        instance_interruption_behavior = "stop"
        max_price                      = lookup(each.value, "spot_max_price", "")
        spot_instance_type             = ""
      }
    }
  }

  subnet_id = coalesce(
    lookup(each.value, "subnet_id", null),
    lookup(var.subnet_map, lookup(each.value, "availability_zone", ""), null),
    length(var.subnet_id) > 0 ? element(var.subnet_id, lookup(each.value, "index", 0) % length(var.subnet_id)) : null
  )
  security_groups             = var.security_group_id
  associate_public_ip_address = lookup(each.value, "associate_public_ip", false)
  key_name                    = var.key_pair_name
  availability_zone           = lookup(each.value, "availability_zone", null)


  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(var.tags, {
      Name = "${var.instance_name_prefix}-root-vol-${lookup(each.value, "index", 0) + 1}"
    })
  }

  tags = merge(var.tags, {
    Name = lookup(each.value, "name", "${var.instance_name_prefix}-${each.key}")
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_ec2_tag" "environment" {
  for_each = { for k, inst in aws_instance.main : k => inst }

  resource_id = each.value.id
  key         = "Index"
  value       = each.key
}

# Attach instances to load balancer target groups
resource "aws_lb_target_group_attachment" "main" {
  for_each = length(var.target_group_arns) > 0 ? {
    for pair in flatten([
      for tg_arn in var.target_group_arns : [
        for k, inst in aws_instance.main : {
          key    = "${k}-${tg_arn}"
          tg_arn = tg_arn
          id     = inst.id
        }
      ]
    ]) : pair.key => pair
  } : {}

  target_group_arn = each.value.tg_arn
  target_id        = each.value.id
}
