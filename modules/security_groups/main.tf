# Security Group for Control Plane
resource "aws_security_group" "control_plane" {
  name        = "${var.environment}-kubeadm-control-plane-sg"
  description = "Security group for kubeadm control plane nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.environment}-control-plane-sg"
  })
}

# Allow internal communication within control plane
resource "aws_security_group_rule" "control_plane_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  self              = true

  description = "Allow all TCP traffic between control plane nodes"
}

# Allow Kubernetes API Server (6443)
resource "aws_security_group_rule" "control_plane_api" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  cidr_blocks       = var.allowed_cidr_blocks

  description = "Allow Kubernetes API Server access"
}

# Allow etcd (2379, 2380)
resource "aws_security_group_rule" "control_plane_etcd" {
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  self              = true

  description = "Allow etcd communication"
}

# Allow scheduler and controller manager (10251, 10252)
resource "aws_security_group_rule" "control_plane_components" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10259
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  self              = true

  description = "Allow Kubernetes components"
}

# Allow SSH (22)
resource "aws_security_group_rule" "control_plane_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  cidr_blocks       = var.allowed_ssh_cidr

  description = "Allow SSH access"
}

# Allow all outbound traffic from control plane
resource "aws_security_group_rule" "control_plane_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.control_plane.id
  cidr_blocks       = ["0.0.0.0/0"]

  description = "Allow all outbound traffic"
}

# Security Group for Worker Nodes
resource "aws_security_group" "worker" {
  name        = "${var.environment}-kubeadm-worker-sg"
  description = "Security group for kubeadm worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.environment}-worker-sg"
  })
}

# Allow internal communication within workers
resource "aws_security_group_rule" "worker_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.worker.id
  self              = true

  description = "Allow all TCP traffic between worker nodes"
}

# Allow communication from control plane
resource "aws_security_group_rule" "worker_from_control_plane" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10259
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.control_plane.id

  description = "Allow communication from control plane"
}

# Allow Kubelet (10250)
resource "aws_security_group_rule" "worker_kubelet" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = var.allowed_cidr_blocks

  description = "Allow Kubelet access"
}

# Allow SSH (22)
resource "aws_security_group_rule" "worker_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = var.allowed_ssh_cidr

  description = "Allow SSH access"
}

# Allow NodePort services (30000-32767)
resource "aws_security_group_rule" "worker_nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = var.allowed_cidr_blocks

  description = "Allow NodePort services"
}

# Allow HTTP (80) from internet
resource "aws_security_group_rule" "worker_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = ["0.0.0.0/0"]

  description = "Allow HTTP from internet"
}

# Allow HTTPS (443) from internet
resource "aws_security_group_rule" "worker_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = ["0.0.0.0/0"]

  description = "Allow HTTPS from internet"
}

# Allow all outbound traffic from workers
resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = ["0.0.0.0/0"]

  description = "Allow all outbound traffic"
}
