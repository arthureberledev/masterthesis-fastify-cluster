provider "aws" {
  region = local.region
}

locals {
  name   = "ma-cluster"
  region = "eu-central-1"

  vpc_cidr = "10.123.0.0/16"
  azs      = ["eu-central-1a", "eu-central-1b"] # In der MA darauf eingehen, dass die azs genutzt werden können, um die Availability zu erhöhen

  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
  intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]

  tags = {
    Example = local.name
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Self Managed Node Group(s)
  #   self_managed_node_group_defaults = {
  #     vpc_security_group_ids = [aws_security_group.additional.id]
  #     iam_role_additional_policies = {
  #       additional = aws_iam_policy.additional.arn
  #     }

  #     instance_refresh = {
  #       strategy = "Rolling"
  #       preferences = {
  #         min_healthy_percentage = 66
  #       }
  #     }
  #   }

  #   self_managed_node_groups = {
  #     spot = {
  #       instance_type = "m5.large"
  #       instance_market_options = {
  #         market_type = "spot"
  #       }

  #       pre_bootstrap_user_data = <<-EOT
  #         echo "foo"
  #         export FOO=bar
  #       EOT

  #       bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

  #       post_bootstrap_user_data = <<-EOT
  #         cd /tmp
  #         sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  #         sudo systemctl enable amazon-ssm-agent
  #         sudo systemctl start amazon-ssm-agent
  #       EOT
  #     }
  #   }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    ma-cluster-wg = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  node_security_group_tags = {
    "kubernetes.io/cluster/${local.name}" = null
  }

  # Fargate Profile(s)
  # fargate_profiles = {
  #   default = {
  #     name = "default"
  #     selectors = [
  #       {
  #         namespace = "kube-system"
  #         labels = {
  #           k8s-app = "kube-dns"
  #         }
  #       },
  #       {
  #         namespace = "default"
  #       }
  #     ]

  #     tags = {
  #       Owner = "test"
  #     }

  #     timeouts = {
  #       create = "20m"
  #       delete = "20m"
  #     }
  #   }
  # }

  # Create a new cluster where both an identity provider and Fargate profile is created
  # will result in conflicts since only one can take place at a time
  # # OIDC Identity provider
  # cluster_identity_providers = {
  #   sts = {
  #     client_id = "sts.amazonaws.com"
  #   }
  # }

  tags = local.tags
}
