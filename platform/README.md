# IDP 平台层

平台级部署资源。首期**引用上游 chart + values 覆盖**，不 fork 上游。

## 结构 Structure

```
platform/
├── helm/
│   ├── kagent/          # kagent controller（引用上游 + values）
│   ├── kmcp/            # kmcp controller（引用上游 + values）
│   └── registry/        # OCI mirror（可选）
├── terraform/           # 集群初始化
└── examples/            # 多团队示例
```

## 部署 Deploy

```bash
# kagent controller
helm upgrade --install kagent-crds \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --version 1.0.0-alpha3 --namespace kagent --create-namespace

helm upgrade --install kagent \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --version 1.0.0-alpha3 --namespace kagent \
  -f helm/kagent/values.yaml
```

> 完整 Substrate 依赖的搭建见 [docs/03-idp/01-cluster-setup.md](../../docs/03-idp/01-cluster-setup.md)。
