# Harness 四种运行时适配器

> The four Harness adapters: kagent / Codex / Claude / BYO.

---

## 核心要点 Key points

Harness 描述「怎么跑」agent，`spec` 四选一：

```yaml
spec:
  kagent: {}    # 或 codex / claude / byo
  workload:
    image: ghcr.io/kagent-dev/kagent/golang-adk@sha256:<digest>
  substrate:
    workerPoolRef: { name: kagent-default }
    snapshotPolicy: { location: s3://ate-snapshots/kagent }
```

---

## 四种 adapter 对比 Comparison

| Adapter | 用途 | 特点 |
|---------|------|------|
| `kagent` | 原生 Go ADK 运行时 | 默认，支持 memory / compaction |
| `codex` | OpenAI Codex 运行时 | 渲染为 CODEX 配置 |
| `claude` | Claude Code 运行时 | 渲染为 Claude 原生配置 |
| `byo` | 自定义 A2A 镜像 | 必须指定 `workload.command`，实现 A2A 契约 |

---

## 选择依据 How to choose

```
场景                                   → 选
─────────────────────────────────────────────
默认 / 通用 agent                        → kagent
已有 Codex 工作流 / 团队用 Codex         → codex
已有 Claude Code 工作流                   → claude
自研运行时 / 特殊镜像                     → byo
```

---

## 完整 Harness 示例 Full example

```yaml
apiVersion: kagent.dev/v1alpha3
kind: Harness
metadata:
  name: kagent
  namespace: kagent
spec:
  kagent:
    memory:                     # 可选：长期记忆
      modelConfigRef: { name: embedding-model }
      ttlDays: 30
    compaction:                 # 可选：上下文压缩
      tokenThreshold: 8000
      eventRetentionSize: 20
  workload:
    image: ghcr.io/kagent-dev/kagent/golang-adk@sha256:<digest>
  env:                          # 可选：环境变量
    - name: LOG_LEVEL
      value: info
    - name: API_TOKEN
      credentialRef:            # 从 Secret 引用
        name: my-secret
        key: token
  substrate:
    workerPoolRef: { name: kagent-default }
    snapshotPolicy: { location: s3://ate-snapshots/kagent }
  allowedAgentTemplates:        # 接纳哪些 template
    selector:
      matchLabels:
        kagent.dev/harness: kagent
```

---

## 关键约束 Constraints

- `workload.image` 必须是 **digest 引用**（`@sha256:...`），Substrate 要求。
- `allowedAgentTemplates` 省略时，Harness **不接纳任何** template。
- BYO harness 必须指定 `workload.command`（Substrate 不用镜像 entrypoint）。
- `env` 中 `value` 与 `credentialRef` 二选一。

---

## 下一步 Next

- 测试与 evals → [05-testing.md](05-testing.md)
- 平台级部署 Harness → [../03-idp/01-cluster-setup.md](../03-idp/01-cluster-setup.md)
