# 多团队示例

展示共享平台上多个团队各自部署 agent 的 namespace 隔离模式。

## 结构

```
examples/
├── team-a/
│   ├── namespace.yaml          # namespace: team-a
│   ├── agenttemplate.yaml      # team-a 的 agent
│   └── rbac.yaml               # team-a 的 RBAC
└── team-b/
    └── ...
```

## 原则

- 每团队一个 namespace，RBAC 限制在其内。
- kagent v2 的引用是**同 namespace** 的：ModelConfig / RemoteMCPServer / skill 都在同一 namespace。
- 平台团队通过 `Harness.allowedAgentTemplates.selector` 控制准入。

> 完整工作流见 [docs/03-idp/04-multi-team.md](../../docs/03-idp/04-multi-team.md)。
