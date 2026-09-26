# hello-agent

最小可运行的 kagent agent 示例。

## 内容

- `agenttemplate.yaml` — 单个 AgentTemplate，内嵌 systemPrompt，无 skill/MCP/plugin。

## 运行

```bash
# 确认当前 kubectl context 指向正确的集群
kubectl config current-context

kubectl apply -f agenttemplate.yaml
kubectl get agenttemplate -n kagent hello-agent
```

> 需要先有 Harness（见 docs/01-basics/04-run-agent.md）。

> **多集群注意**：本示例为单集群设计。若同时管理多个集群，建议始终用 `--context <cluster>` 显式指定目标，避免误操作。详见 [docs/01-basics/05-multi-cluster.md](../../docs/01-basics/05-multi-cluster.md)。
