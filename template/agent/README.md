# Agent 项目模板

可复制的 agent 项目脚手架。复制后填入配置即可部署到 K8s。

## 用法

```bash
cp -r template/agent my-agent
# 修改 harness.yaml / agenttemplate.yaml / modelconfig.yaml / remotemcpserver.yaml
# 确认当前 kubectl context 指向正确的集群后再 apply
kubectl config current-context
kubectl apply -f harness.yaml -f modelconfig.yaml -f remotemcpserver.yaml -f agenttemplate.yaml
```

> 所有 `REPLACE_WITH_DIGEST` 占位符需替换为真实 OCI digest。

## 多集群管理 Multi-Cluster

若你同时在管理多个 Kubernetes 集群，请注意：

1. 执行 `kubectl apply` 前先确认当前 context 目标。
2. 推荐使用 `--context <cluster>` 显式指定集群，避免误操作。
3. 参见 [docs/01-basics/05-multi-cluster.md](docs/01-basics/05-multi-cluster.md) 获取完整的多集群管理指南。
