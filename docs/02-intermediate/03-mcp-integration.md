# MCP 集成：RemoteMCPServer + ToolBinding

> Integrate MCP tools into your agent.

---

## 核心命令 Core commands

```bash
# 1. 定义 RemoteMCPServer
kubectl apply -f remotemcpserver.yaml

# 2. AgentTemplate 中声明 ToolBinding
kubectl apply -f agenttemplate.yaml

# 3. 验证工具可用
kubectl get remotemcpserver -n kagent
```

---

## 概念 Concept

```
RemoteMCPServer（CRD）      AgentTemplate.tools[]（ToolBinding）
     │ 定义一个 MCP server        │ 引用 server 并可选筛选工具
     └────────────────────────────┘
                  │
                  ▼
        agent 通过 A2A 调用 MCP 工具
```

---

## RemoteMCPServer 示例

```yaml
apiVersion: kagent.dev/v1alpha3
kind: RemoteMCPServer
metadata:
  name: k8s-mcp
  namespace: kagent
spec:
  transport: streamable-http
  url: http://k8s-mcp.kagent.svc:8080/mcp
```

> 具体字段以 v1.0.0-alpha3 的 `remotemcpserver_types.go` 为准，字段可能演进。

---

## ToolBinding 示例

在 `AgentTemplate.spec.tools[]` 中声明：

```yaml
spec:
  tools:
    # 引用 MCP server 的全部工具
    - mcp:
        server:
          kind: RemoteMCPServer
          name: k8s-mcp

    # 只暴露部分工具 + 每次调用前需批准
    - mcp:
        server:
          kind: RemoteMCPServer
          name: k8s-mcp
        tools: ["get_pods", "describe_pod"]
        requireApproval: true
```

字段：

| 字段 | 作用 |
|------|------|
| `server` | 引用同 namespace 的 `RemoteMCPServer` |
| `tools` | 可选，限制暴露哪些工具（空 = 全部） |
| `requireApproval` | 每次调用前暂停请求批准 |

---

## 工具来源的两种绑定 Two binding types

`ToolBinding` 是二选一（`mcp` 或 `agent`，不可同时）：

```yaml
spec:
  tools:
    # 类型 A：绑定 MCP server
    - mcp:
        server: { kind: RemoteMCPServer, name: k8s-mcp }

    # 类型 B：把另一个 AgentTemplate 当作工具（agent-to-agent）
    - agent:
        name: code-reviewer
        description: 当需要审查代码时路由到此 agent
        templateRef: { name: code-reviewer-template }
        isolation: Dedicated   # Shared 或 Dedicated
```

---

## 下一步 Next

- Harness 四种 adapter → [04-harness.md](04-harness.md)
- 完整 MCP 示例 → [../../examples/k8s-agent/](../../examples/k8s-agent/)
