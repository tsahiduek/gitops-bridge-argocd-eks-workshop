data "aws_region" "current" {}

locals {
  addon_context = {
    eks_cluster_id = "gitops-bridge"
  }
  gitops_workload_org = "ssh://${aws_iam_user_ssh_key.gitops.id}@git-codecommit.${data.aws_region.current.id}.amazonaws.com"
  gitops_workload_repo = "v1/repos/${local.addon_context.eks_cluster_id}-argocd"
  gitops_workload_url = "${local.gitops_workload_org}/${local.gitops_workload_repo}"
  ssh_key_basepath = var.ssh_key_basepath
  git_private_ssh_key = "${local.ssh_key_basepath}/gitops_ssh.pem"
  git_private_ssh_key_config = "${local.ssh_key_basepath}/config"
}

resource "aws_codecommit_repository" "argocd" {
  repository_name = "${local.addon_context.eks_cluster_id}-argocd"
  description     = "CodeCommit repository for ArgoCD"
}

resource "aws_iam_user" "gitops" {
  name = "${local.addon_context.eks_cluster_id}-gitops"
  path = "/"
}

resource "aws_iam_user_ssh_key" "gitops" {
  username   = aws_iam_user.gitops.name
  encoding   = "SSH"
  public_key = tls_private_key.gitops.public_key_openssh
}

resource "tls_private_key" "gitops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.gitops.private_key_pem
  filename        = pathexpand(local.git_private_ssh_key)
  file_permission = "0400"
}

resource "local_file" "ssh_config" {
  content         = <<EOF
Host git-codecommit.*.amazonaws.com
  User ${aws_iam_user.gitops.unique_id}
  IdentityFile ~/.ssh/gitops_ssh.pem
EOF
  filename        = pathexpand(local.git_private_ssh_key_config)
  file_permission = "0600"
}

data "aws_iam_policy_document" "gitops_access" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ]
    effect = "Allow"
    resources = [
      aws_codecommit_repository.argocd.arn
    ]
  }
}

resource "aws_iam_policy" "gitops_access" {
  name   = "${local.addon_context.eks_cluster_id}-gitops"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.gitops.name
  policy_arn = aws_iam_policy.gitops_access.arn
}

output "environment" {
  value = <<EOF
export GITOPS_IAM_SSH_KEY_ID=${aws_iam_user_ssh_key.gitops.id}
export GITOPS_IAM_SSH_USER=${aws_iam_user.gitops.unique_id}
export GITOPS_REPO_URL_ARGOCD=${local.gitops_workload_url}
EOF
}

output "gitops_workload_org" {
  value = local.gitops_workload_org
}
output "gitops_workload_repo" {
  value = local.gitops_workload_repo
}
output "gitops_workload_url" {
  value = local.gitops_workload_url
}
output "configure_argocd" {
  value = "argocd repo add ${local.gitops_workload_url} --ssh-private-key-path $${HOME}/.ssh/gitops_ssh.pem --insecure-ignore-host-key --upsert --name git-repo"
}
output "git_clone" {
  value = "git clone ${local.gitops_workload_url} gitops-bridge-eks-workshop"
}
