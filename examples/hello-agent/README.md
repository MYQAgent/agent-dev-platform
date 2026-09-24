# hello-agent

最小可运行的 kagent agent 示例。

## 内容

- `agenttemplate.yaml` — 单个 AgentTemplate，内嵌 systemPrompt，无 skill/MCP/plugin。

## 运行

```bash
kubectl apply -f agenttemplate.yaml
kubectl get agenttemplate -n kagent hello-agent
```

> 需要先有 Harness（见 docs/01-basics/04-run-agent.md）。
