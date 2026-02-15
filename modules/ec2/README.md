# EC2 Module

Flexible Terraform module for creating AWS EC2 instances with support for multiple deployment patterns.

## Features

- **Dual Operating Modes**: Simple count-based or explicit per-instance configuration
- **Flexible Subnet Selection**: Direct subnet ID, AZ-based lookup, or round-robin distribution
- **Auto Load Balancer Registration**: Automatic attachment to target groups
- **Customizable Per Instance**: Override instance type, subnet, AZ, and more per instance
- **AMI Filtering**: Dynamic AMI selection based on patterns
- **Tagging**: Comprehensive tagging support

## Usage Scenarios

### Scenario 1: Simple Count-Based Deployment

Create multiple identical instances with automatic round-robin subnet distribution.

```terraform
module "web_servers" {
  source = "../../modules/ec2"
  
  environment          = "staging"
  instance_name_prefix = "web-server"
  instance_count       = 3
  instance_type        = "t3.small"
  
  # Round-robin distribution across subnets
  subnet_ids = [
    "subnet-aaa",
    "subnet-bbb",
    "subnet-ccc"
  ]
  
  ami_name_pattern  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner         = "099720109477"  # Canonical
  security_group_id = "sg-12345"
  key_pair_name     = "my-key"
  
  tags = {
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
```

**Result**: Creates 3 instances distributed as:
- `instance-0` → subnet-aaa
- `instance-1` → subnet-bbb
- `instance-2` → subnet-ccc

---

### Scenario 2: Explicit Instance Configuration with AZ-Based Subnet Selection

Define each instance individually with availability zone-based subnet selection. Best for production environments requiring explicit control.

```terraform
module "control_plane" {
  source = "../../modules/ec2"
  
  environment          = "production"
  instance_name_prefix = "k8s-control-plane"
  
  # Map availability zones to subnet IDs
  subnet_map = {
    "ap-south-1a" = "subnet-xxx"
    "ap-south-1b" = "subnet-yyy"
    "ap-south-1c" = "subnet-zzz"
  }
  
  # Define each instance with specific configuration
  instances = {
    cp-1 = {
      availability_zone = "ap-south-1a"
      instance_type     = "t3.large"
      name              = "prod-control-plane-1"
    }
    cp-2 = {
      availability_zone = "ap-south-1b"
      instance_type     = "t3.large"
      name              = "prod-control-plane-2"
    }
    cp-3 = {
      availability_zone = "ap-south-1c"
      instance_type     = "t3.xlarge"  # Different size
      name              = "prod-control-plane-3"
    }
  }
  
  ami_name_pattern  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner         = "099720109477"
  security_group_id = "sg-67890"
  key_pair_name     = "prod-key"
  
  root_volume_size  = 100
  root_volume_type  = "gp3"
  
  tags = {
    Environment = "production"
    Role        = "control-plane"
    ManagedBy   = "Terraform"
  }
}
```

**Result**: Creates 3 instances with:
- Explicit AZ placement via `subnet_map` lookup
- Different instance types per instance
- Custom naming per instance

---

### Scenario 3: Direct Subnet ID Assignment

Override all automatic selection and specify exact subnet IDs per instance.

```terraform
module "database_servers" {
  source = "../../modules/ec2"
  
  environment          = "production"
  instance_name_prefix = "postgres"
  
  instances = {
    db-primary = {
      subnet_id     = "subnet-private-1a"
      instance_type = "r5.xlarge"
      name          = "postgres-primary"
    }
    db-replica-1 = {
      subnet_id     = "subnet-private-1b"
      instance_type = "r5.large"
      name          = "postgres-replica-1"
    }
    db-replica-2 = {
      subnet_id     = "subnet-private-1c"
      instance_type = "r5.large"
      name          = "postgres-replica-2"
    }
  }
  
  ami_name_pattern  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner         = "099720109477"
  security_group_id = "sg-database"
  key_pair_name     = "db-key"
  
  root_volume_size  = 200
  root_volume_type  = "gp3"
  
  tags = {
    Environment = "production"
    Role        = "database"
    ManagedBy   = "Terraform"
  }
}
```

**Result**: Each instance placed in exact specified subnet, ignoring `subnet_map` and `subnet_ids`.

---

### Scenario 4: Load Balancer Auto-Registration

Automatically register instances to one or more target groups.

```terraform
module "backend_servers" {
  source = "../../modules/ec2"
  
  environment          = "staging"
  instance_name_prefix = "api-backend"
  
  instances = {
    backend-1 = {
      availability_zone   = "us-west-2a"
      instance_type       = "t3.medium"
      associate_public_ip = true
    }
    backend-2 = {
      availability_zone   = "us-west-2b"
      instance_type       = "t3.medium"
      associate_public_ip = true
    }
    backend-3 = {
      availability_zone   = "us-west-2c"
      instance_type       = "t3.medium"
      associate_public_ip = true
    }
  }
  
  subnet_map = {
    "us-west-2a" = "subnet-aaa"
    "us-west-2b" = "subnet-bbb"
    "us-west-2c" = "subnet-ccc"
  }
  
  # Automatically attach to multiple target groups
  target_group_arns = [
    "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/api-http/abc123",
    "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/api-https/def456"
  ]
  
  ami_name_pattern  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner         = "099720109477"
  security_group_id = "sg-backend"
  key_pair_name     = "backend-key"
  
  tags = {
    Environment = "staging"
    Role        = "backend"
    ManagedBy   = "Terraform"
  }
}
```

**Result**: 
- Each instance automatically registered to **both** target groups
- 6 total target group attachments created (3 instances × 2 target groups)

---

### Scenario 5: Mixed Configuration with Fallback

Use both `subnet_map` and `subnet_ids` for flexible placement with fallback.

```terraform
module "worker_nodes" {
  source = "../../modules/ec2"
  
  environment          = "dev"
  instance_name_prefix = "k8s-worker"
  
  # Fallback subnet list
  subnet_ids = ["subnet-default-1", "subnet-default-2"]
  
  # AZ-specific subnet mapping
  subnet_map = {
    "ap-south-1a" = "subnet-specific-a"
    "ap-south-1b" = "subnet-specific-b"
  }
  
  instances = {
    worker-1 = {
      availability_zone = "ap-south-1a"  # Uses subnet_map → subnet-specific-a
      instance_type     = "t3.medium"
    }
    worker-2 = {
      availability_zone = "ap-south-1b"  # Uses subnet_map → subnet-specific-b
      instance_type     = "t3.medium"
    }
    worker-3 = {
      # No AZ specified → falls back to round-robin from subnet_ids
      instance_type = "t3.medium"
    }
  }
  
  ami_name_pattern  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner         = "099720109477"
  security_group_id = "sg-workers"
  key_pair_name     = "dev-key"
}
```

**Result**:
- `worker-1` → subnet-specific-a (via subnet_map)
- `worker-2` → subnet-specific-b (via subnet_map)
- `worker-3` → subnet-default-1 (fallback to round-robin)

---

### Scenario 6: Spot Instances for Cost Optimization

Use EC2 spot instances for workloads that can tolerate interruptions (e.g., worker nodes, batch processing, dev environments). Spot instances offer up to 70% cost savings compared to on-demand pricing.

```terraform
module "k8s_workers" {
  source = "../../modules/ec2"
  
  environment          = "staging"
  instance_name_prefix = "k8s-worker"
  
  subnet_map = {
    "ap-south-1a" = "subnet-xxx"
    "ap-south-1b" = "subnet-yyy"
  }
  
  instances = {
    # Control plane on-demand (high availability required)
    control-plane = {
      availability_zone = "ap-south-1a"
      instance_type     = "t3.small"
      name              = "k8s-control-plane"
      use_spot          = false  # On-demand for control plane
    }
    
    # Workers on spot (can tolerate interruptions)
    worker-1 = {
      availability_zone = "ap-south-1a"
      instance_type     = "t3.large"
      name              = "k8s-worker-1"
      use_spot          = true
      spot_max_price    = "0.025"  # Max $0.025/hour (current t3.large spot ~$0.018)
    }
    
    worker-2 = {
      availability_zone = "ap-south-1b"
      instance_type     = "t3.large"
      name              = "k8s-worker-2"
      use_spot          = true
      spot_max_price    = ""  # Empty = max on-demand price
    }
  }
  
  ami_name_pattern  = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner         = "099720109477"
  security_group_id = "sg-k8s"
  key_pair_name     = "myself"
  
  tags = {
    Environment = "staging"
    CostCenter  = "dev"
  }
}
```

**Spot Instance Configuration**:
- `use_spot = true`: Requests spot instance instead of on-demand
- `spot_max_price`: Maximum price you're willing to pay per hour
  - Set to specific value (e.g., `"0.025"`) to cap costs
  - Set to `""` (empty string) to pay up to on-demand price
- `instance_interruption_behavior = "terminate"`: Instances terminate when interrupted
- `spot_instance_type = "persistent"`: Spot request persists until cancelled

**Cost Example (ap-south-1)**:
- t3.large on-demand: $0.0608/hour = $43.78/month
- t3.large spot: ~$0.018/hour = $12.96/month (70% savings)
- With 70% monthly downtime (terraform destroy): $3.89/month

**Best Practices**:
- ✅ **Use for**: Worker nodes, batch jobs, dev/staging environments, stateless workloads
- ❌ **Avoid for**: Control planes, databases, stateful applications requiring high availability
- 💡 **Tip**: Set `spot_max_price = ""` to ensure availability at current spot price
- 💡 **Tip**: Use with terraform destroy workflow for maximum savings when not in use

---

## Subnet Selection Priority

The module uses **coalesce** logic to determine subnet placement:

1. **Explicit `subnet_id`** in instance configuration (highest priority)
2. **`subnet_map[availability_zone]`** lookup (if AZ specified)
3. **Round-robin from `subnet_ids`** list (fallback, uses index % length)

```terraform
subnet_id = coalesce(
  lookup(each.value, "subnet_id", null),                                    # 1. Direct subnet_id
  lookup(var.subnet_map, lookup(each.value, "availability_zone", ""), null), # 2. AZ lookup
  element(var.subnet_ids, lookup(each.value, "index", 0) % length(var.subnet_ids)) # 3. Round-robin
)
```

---

## Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `environment` | string | Environment name (e.g., staging, production) |
| `instance_name_prefix` | string | Prefix for instance names |
| `ami_name_pattern` | string | AMI name pattern to search for |
| `security_group_id` | string | Security group ID to attach |
| `key_pair_name` | string | EC2 key pair name for SSH access |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_count` | number | 1 | Number of instances (used when `instances` is empty) |
| `instance_type` | string | "t3.medium" | Default instance type (fallback) |
| `instances` | map(object) | {} | Per-instance configuration map |
| `subnet_ids` | list(string) | [] | List of subnet IDs for round-robin |
| `subnet_map` | map(string) | {} | Map of AZ → subnet_id |
| `ami_owner` | string | "099720109477" | AMI owner ID (default: Canonical) |
| `root_volume_size` | number | 30 | Root volume size in GB |
| `root_volume_type` | string | "gp3" | Root volume type |
| `iam_instance_profile` | string | "" | IAM instance profile name |
| `target_group_arns` | list(string) | [] | Target group ARNs for auto-registration |
| `user_data_template` | string | "" | Path to user data script template |
| `user_data_variables` | map(string) | {} | Variables to pass to user data template |
| `tags` | map(string) | {} | Additional tags |

### Instances Object Schema

```terraform
instances = {
  "instance-key" = {
    subnet_id           = optional(string)  # Direct subnet ID
    availability_zone   = optional(string)  # AZ for subnet_map lookup
    instance_type       = optional(string)  # Override instance type
    associate_public_ip = optional(bool)    # Enable public IP
    name                = optional(string)  # Custom instance name
    use_spot            = optional(bool)    # Use spot instance (default: false)
    spot_max_price      = optional(string)  # Max spot price per hour (empty = on-demand price)
  }
}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_ids` | List of EC2 instance IDs |
| `private_ips` | List of private IP addresses |
| `public_ips` | List of public IP addresses (if assigned) |
| `availability_zones` | List of availability zones |

---



## Notes

- **AMI Selection**: Module uses latest AMI matching the pattern. Add lifecycle `ignore_changes = [ami]` to prevent replacements on AMI updates.
- **Public IPs**: Set `associate_public_ip = true` per instance or in the list for count-based deployments.
- **Target Group Registration**: Instances are automatically registered to all specified target groups using nested loops.
- **Volume Encryption**: Root volumes are always encrypted.
- **Tagging**: Instance name comes from `instance_name_prefix` + instance key, or from the `name` field in instances map.

---

## Common AMI Patterns

```terraform
# Ubuntu 22.04 LTS
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
ami_owner        = "099720109477"  # Canonical

# Amazon Linux 2
ami_name_pattern = "amzn2-ami-hvm-*-x86_64-gp2"
ami_owner        = "137112412989"  # Amazon

# Amazon Linux 2023
ami_name_pattern = "al2023-ami-*-x86_64"
ami_owner        = "137112412989"  # Amazon

# RHEL 9
ami_name_pattern = "RHEL-9*-x86_64-*"
ami_owner        = "309956199498"  # Red Hat
```

---
