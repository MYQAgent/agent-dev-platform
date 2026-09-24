# 治理

> Governance for multi-team agent development.

---

## 核心要点 Key points

治理覆盖三个维度：**安全**（谁能做什么）、**质量**（skill 评审）、**可观测**（出问题能定位）。

```
治理
├── 安全 Security     → RBAC + secret 管理 + MCP 工具授权
├── 质量 Quality      → skill review 清单 + evals 门槛
└── 可观测 Observability → OTEL 追踪 + 指标 + 日志
```

---

## 安全 Security

| 关注点 | 措施 |
|--------|------|
| 命名空间隔离 | 每团队一个 namespace，RBAC 限制 |
| Secret 管理 | ModelConfig 的 API key 用 Secret 引用，不用明文 |
| MCP 工具授权 | `ToolBinding.requireApproval` 控制敏感工具 |
| 只读集群访问 | MCP server 用 `--read-only` 防误改 |
| Harness 准入 | `allowedAgentTemplates.selector` 限制谁能跑 |

---

## 质量 Quality

- skill 合并前必须通过 `skills-ref validate`
- evals 通过率设门槛（如 ≥ 80%）
- 使用 review 清单（见 [../../governance/review-checklist.md](../../governance/review-checklist.md)）

---

## 可观测 Observability

kagent 支持 OpenTelemetry：

- 追踪：agent 调用链、tool 调用
- 指标：controller 指标 + ServiceMonitor
- 日志：harness 的 OTEL logs

配置见 [../../governance/observability/](../../governance/observability/)。

---

## 下一步 Next

- 多团队工作流 → [04-multi-team.md](04-multi-team.md)
