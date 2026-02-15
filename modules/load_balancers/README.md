# Load Balancers Module

This module creates AWS Application Load Balancer (ALB) and Network Load Balancer (NLB) for a Kubernetes cluster on kubeadm.

## Architecture

- **Gateway ALB**: Public-facing Application Load Balancer for HTTP/HTTPS ingress traffic to worker nodes
- **API Server NLB**: Network Load Balancer for Kubernetes API server access (TCP 6443) to control plane nodes

## Components Created

### Gateway ALB
- Application Load Balancer (internet-facing)
- HTTP target group (port 80)
- HTTPS target group (port 443, ready for SSL certificate)
- HTTP listener
- Security group with ingress from internet (80, 443) and egress to workers

### API Server NLB
- Network Load Balancer (public or internal)
- TCP target group (port 6443)
- TCP listener
- Security group rules to allow API access from trusted CIDRs

## Usage

### Basic Example

```terraform
module "load_balancers" {
  source = "../../modules/load_balancers"

  environment                      = "staging"
  vpc_id                           = module.vpc.vpc_id
  subnet_ids                       = module.vpc.public_subnet_ids
  worker_security_group_id         = module.security_groups.worker_sg_id
  control_plane_security_group_id  = module.security_groups.control_plane_sg_id
  
  # Restrict API Server access to your IP
  api_server_allowed_cidrs = ["YOUR_IP/32"]
  
  tags = {
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
```

### With HTTPS Certificate

```terraform
module "load_balancers" {
  source = "../../modules/load_balancers"

  environment                = "staging"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  worker_security_group_id   = module.security_groups.worker_sg_id
  control_plane_security_group_id = module.security_groups.control_plane_sg_id
  
  # Optional: Add ACM certificate ARN for HTTPS
  gateway_certificate_arn    = "arn:aws:acm:region:account:certificate/xxx"
  
  api_server_allowed_cidrs   = ["0.0.0.0/0"]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `environment` | Environment name | `string` | - | yes |
| `vpc_id` | VPC ID where load balancers will be deployed | `string` | - | yes |
| `subnet_ids` | List of subnet IDs for load balancer | `list(string)` | - | yes |
| `worker_security_group_id` | Worker nodes security group ID | `string` | - | yes |
| `control_plane_security_group_id` | Control plane nodes security group ID | `string` | - | yes |
| `api_server_allowed_cidrs` | CIDR blocks allowed to access API Server | `list(string)` | `["0.0.0.0/0"]` | no |
| `tags` | Common tags to apply to all resources | `map(string)` | `{}` | no |
| `gateway_certificate_arn` | ARN of ACM certificate for HTTPS listener | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| `gateway_alb_dns_name` | DNS name of the Gateway ALB |
| `gateway_alb_arn` | ARN of the Gateway ALB |
| `gateway_http_target_group_arn` | ARN of the HTTP target group |
| `gateway_https_target_group_arn` | ARN of the HTTPS target group |
| `api_server_nlb_dns_name` | DNS name of the API Server NLB |
| `api_server_nlb_arn` | ARN of the API Server NLB |
| `api_server_target_group_arn` | ARN of the API Server target group |

## Post-Deployment Configuration

### Option 1: AWS Load Balancer Controller (Recommended)

For dynamic management of load balancers via Kubernetes services:

#### 1. Create IAM Policy

```bash
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json
```

#### 2. Attach Policy to Worker Node IAM Role

```bash
aws iam attach-role-policy \
  --role-name <YOUR_WORKER_NODE_IAM_ROLE> \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy
```

#### 3. Install AWS Load Balancer Controller

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create ServiceAccount
kubectl create serviceaccount aws-load-balancer-controller -n kube-system

# Install controller (kubeadm version - no IRSA)
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=staging-kubeadm-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

#### 4. Deploy Gateway with LoadBalancer Service

Create `gateway-values.yaml`:

```yaml
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
    
deployment:
  kind: DaemonSet

ports:
  web:
    port: 80
    exposedPort: 80
  websecure:
    port: 443
    exposedPort: 443
```

Install Gateway:

```bash
helm repo add gateway https://gateway.github.io/charts
helm install gateway gateway/gateway -n gateway --create-namespace -f gateway-values.yaml
```

The controller will automatically create and manage an NLB for Gateway.

### Option 2: Manual Target Registration

If not using AWS Load Balancer Controller, manually register instances:

#### Register Worker Instances to Gateway Target Group

```bash
# Get target group ARN
TG_ARN=$(terraform output -raw gateway_http_target_group_arn)

# Register instances
aws elbv2 register-targets \
  --target-group-arn $TG_ARN \
  --targets Id=i-1234567890abcdef0 Id=i-0987654321fedcba0
```

#### Register Control Plane Instances to API Server Target Group

```bash
# Get target group ARN
API_TG_ARN=$(terraform output -raw api_server_target_group_arn)

# Register control plane instances
aws elbv2 register-targets \
  --target-group-arn $API_TG_ARN \
  --targets Id=i-controlplane1 Id=i-controlplane2
```

### Configure kubectl to Use API Server NLB

```bash
# Get NLB DNS name
API_SERVER_DNS=$(terraform output -raw api_server_nlb_dns_name)

# Update kubeconfig
kubectl config set-cluster staging-kubeadm-cluster \
  --server=https://${API_SERVER_DNS}:6443 \
  --insecure-skip-tls-verify=true

# Or with proper CA cert
kubectl config set-cluster staging-kubeadm-cluster \
  --server=https://${API_SERVER_DNS}:6443 \
  --certificate-authority=/path/to/ca.crt
```

## Security Considerations

1. **API Server Access**: By default, `api_server_allowed_cidrs` is `0.0.0.0/0`. **Change this to your specific IP or VPN CIDR** before applying:
   ```terraform
   api_server_allowed_cidrs = ["YOUR_IP/32", "VPN_CIDR/24"]
   ```

2. **HTTPS for Gateway**: Uncomment the HTTPS listener in `main.tf` and provide a valid ACM certificate ARN for production use.

3. **Security Groups**: The module creates security group rules to allow:
   - Internet → Gateway ALB (80, 443)
   - Gateway ALB → Workers (80)
   - Trusted CIDRs → API Server NLB (6443)
   - API Server NLB → Control Plane (6443)

## Troubleshooting

### ALB/NLB Not Healthy

Check target health:
```bash
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>
```

Verify security group rules allow traffic from LB to instances.

### AWS Load Balancer Controller Not Creating LBs

Check controller logs:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

Common issues:
- IAM permissions missing
- Security group restrictions
- Subnet tags missing (add `kubernetes.io/role/elb=1` for public subnets)

### Gateway Not Accessible

1. Verify service has external IP/hostname:
   ```bash
   kubectl get svc -n gateway
   ```

2. Check Gateway logs:
   ```bash
   kubectl logs -n gateway daemonset/gateway
   ```

3. Verify worker security group allows traffic from ALB

## Notes

- **NLB for kubeadm**: Network Load Balancers don't use security groups directly. Security is handled at the target instance level.
- **Subnet Selection**: Use public subnets for internet-facing load balancers, private subnets for internal-only.
- **Cross-Zone Load Balancing**: Enabled by default for both ALB and NLB to distribute traffic across all AZs.

## Clean Up

To remove load balancers:

```bash
terraform destroy -target=module.load_balancers
```

**Warning**: If using AWS Load Balancer Controller, delete Kubernetes services first to clean up controller-managed resources:

```bash
kubectl delete svc gateway -n gateway
helm uninstall gateway -n gateway
```

## License

MIT
