# Agent 项目模板

可复制的 agent 项目脚手架。复制后填入配置即可部署到 K8s。

## 用法

```bash
cp -r template/agent my-agent
# 修改 harness.yaml / agenttemplate.yaml / modelconfig.yaml / remotemcpserver.yaml
kubectl apply -f harness.yaml -f modelconfig.yaml -f remotemcpserver.yaml -f agenttemplate.yaml
```

> 所有 `REPLACE_WITH_DIGEST` 占位符需替换为真实 OCI digest。
