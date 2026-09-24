# Terraform 集群初始化

用于初始化 K8s 集群与基础依赖。

## 结构

```
terraform/
├── main.tf          # provider + cluster
├── variables.tf     # 输入变量
└── outputs.tf       # 输出（kubeconfig 等）
```

## 用法

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

> 具体云 provider（EKS/GKE/AKS/Kind）按需选择。Substrate 与 kagent 的部署通常由 Helm 完成，terraform 负责集群与网络等底座。
