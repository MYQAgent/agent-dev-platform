# Harness 四种运行时适配器

> The four Harness adapters: kagent / Codex / Claude / BYO.

> **统一镜像源说明**：本指南所有示例使用 `localhost:5000` 作为演示 registry。  
> 你只需 `docker run -d -p 5000:5000 --name registry registry:2` 即可启动。  
> 官方运行镜像（golang-adk 等）来自 ghcr.io/kagent-dev/，国内用户见镜像加速指南。  
> 生产环境请替换为你的实际 registry 地址。

---

## 一句话理解

**Harness 是 agent 的"引擎选择器"**——决定 agent 跑在哪个运行时上。
`spec` 里四选一：`kagent` / `codex` / `claude` / `byo`，每个适配器使用不同的运行时镜像和配置渲染方式。

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

## 决策流程图 Decision tree

```
你的场景？
│
├─ 第一次用 / 通用 agent / 不确定选什么
│   └─ kagent ✅（默认推荐，内置记忆+上下文压缩）
│
├─ 团队已用 OpenAI Codex 工作流
│   └─ codex（自动渲染为 CODEX 配置）
│
├─ 团队已用 Claude Code 工作流
│   └─ claude（自动渲染为 Claude 原生配置）
│
├─ 自研运行时 / 特殊容器 / 需要官方镜像未包含的工具
│   └─ byo（自己写 Dockerfile + 实现 A2A 契约）
```

---

## 特性对比矩阵 Comparison

| 特性 | kagent | codex | claude | byo |
|------|--------|-------|--------|-----|
| 运行时 | Go ADK (Substrate) | OpenAI Codex | Claude Code | 自定义镜像 |
| **使用镜像** | `golang-adk` | `golang-adk`（同） | `golang-adk`（同） | 自建镜像 |
| 镜像来源 | 官方 ghcr.io | 官方 ghcr.io | 官方 ghcr.io | 你的 registry |
| **需要构建 Docker 镜像** | ❌ | ❌ | ❌ | ✅ |
| 内置记忆 (memory) | ✅ | ❌ | ❌ | ❌（自实现）|
| 上下文压缩 (compaction) | ✅ | ❌ | ❌ | ❌（自实现）|
| 预装 CLI 工具 | kubectl, bash, jq 等 | 同上 | 同上 | 你决定 |
| MCP 工具调用 | ✅ 通过 tools server | ✅ | ✅ | ✅ |
| 额外依赖 | 无 | Codex CLI | Claude CLI | A2A SDK |
| 学习成本 | ⭐ 低 | ⭐⭐ 中 | ⭐⭐ 中 | ⭐⭐⭐ 高 |
| 灵活度 | 中 | 低 | 低 | 高 |
| 推荐人群 | 通用（默认） | Codex 用户 | Claude 用户 | 高级用户 |

---

## 真实场景案例 Scenarios

```
kagent   ← 小张第一次部署 agent，选默认，10 分钟跑通

codex    ← 团队全员用 Codex CLI 开发，Harness 配置自动渲染为
            CODEX 格式，无缝接入 OpenAI 生态

claude   ← 团队习惯 Claude Code 写代码，Harness 渲染为 Claude
            原生配置，agent 行为与本地 Claude 体验一致

byo      ← 需要 gVisor 沙箱外的特殊运行时，或自研推理引擎，
            自己控制完整镜像内容
```

---

## 关于构建镜像 Image building

### kagent / codex / claude — 不需要构建 Docker 镜像

直接使用官方提供的运行时镜像：

```yaml
workload:
  image: ghcr.io/kagent-dev/kagent/golang-adk@sha256:699c7a36daa0050d5954f42ad3b614690d825664cf64ffe8871dbe20dc68464e
```

镜像来源：`https://github.com/kagent-dev/kagent/blob/main/go/Dockerfile`

### byo — 需要构建自定义镜像

自己写 Dockerfile，实现 A2A 协议契约，然后在 Harness 中指定：

```bash
# 构建并推送到本地 registry
docker build -t localhost:5000/my-org/custom-agent:0.1.0 .
docker push localhost:5000/my-org/custom-agent:0.1.0
# 获取 digest
docker inspect localhost:5000/my-org/custom-agent:0.1.0 | jq -r '.[0].RepoDigests[0]'
```

```yaml
spec:
  byo: {}
  workload:
    image: localhost:5000/my-org/custom-agent@sha256:<digest>
    command: ["/app/agent"]
```

### 区分概念：Skill OCI 制品 ≠ 容器镜像

```
Skill OCI 制品：   oras push localhost:5000/my-org/k8s-skills:0.1.0 ./skills
                  → 这是发布 skill 内容（SKILL.md + scripts）
                  → 工具链：oras / skills-ref / jq，安装见 03-skills/00-toolchain.md
容器镜像：         docker build -t localhost:5000/my-org/custom-agent:0.1.0 . && docker push
                  → 这是构建运行时环境（仅 byo 需要）
```

---

## 工具依赖说明 Tool dependencies

### Skill 需要的 CLI 工具从哪里来？

在 kagent 架构中，Agent 运行时（golang-adk）和 CLI 工具是**分离部署**的：

```
┌──────────────────────────────────────────────┐
│  golang-adk（Agent 运行时）                    │
│  - 运行 Google ADK agent                      │
│  - 通过 MCP 协议调用工具                       │
│  - 内置基础 CLI：bash, jq 等                   │
└──────────────┬───────────────────────────────┘
               │ MCP over HTTP
               ▼
┌──────────────────────────────────────────────┐
│  kagent-tools（MCP 工具服务器）                │
│  - 独立 Helm subchart 部署                    │
│  - 镜像：ghcr.io/kagent-dev/kagent/tools     │
│  - 预装：kubectl, helm, istio, argocd 等      │
│  - Agent 通过 RemoteMCPServer CR 发现和调用   │
└──────────────────────────────────────────────┘
```

**加载方式：** tools 服务器是一个独立的 Deployment，通过 Helm subchart 自动安装，注册为 `RemoteMCPServer` CR。Agent 通过网络调用它的 MCP 端点（`http://kagent-tools:8084/mcp`），而不是作为 sidecar 或挂载到 agent 容器内。

工具镜像来源：`https://github.com/kagent-dev/tools/blob/main/Dockerfile`

### 各 adapter 的工具支持

| Adapter | 基础 CLI（golang-adk 内置）| 扩展工具（kagent-tools MCP）| 自定义工具 |
|---------|--------------------------|--------------------------|-----------|
| kagent | bash, jq 等 | kubectl, helm, istio, argo 等 | 任意 MCP server |
| codex | 同上 | 同上 | 任意 MCP server |
| claude | 同上 | 同上 | 任意 MCP server |
| byo | 你决定 | 可选，仍可引用 | 任意 MCP server |

### 责任分工

```
skill 作者   → SKILL.md 的 compatibility 字段声明需要哪些工具
               比如 Requires kubectl and access to a Kubernetes cluster

平台团队     → 确保 golang-adk 或 kagent-tools 包含 skill 所需工具

如果缺少某个工具：
  a) 在 tools 仓库提 PR 添加（社区方案）
  b) 部署自己的 MCP Server，通过 RemoteMCPServer CR 注册
  c) 用 byo adapter，在自定义镜像中装好所有工具
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
    image: ghcr.io/kagent-dev/kagent/golang-adk@sha256:699c7a36daa0050d5954f42ad3b614690d825664cf64ffe8871dbe20dc68464e
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

- `workload.image` 必须是 **digest 引用**（`@sha256:...`），Substrate 要求，不能用 tag。
- `allowedAgentTemplates` 省略时，Harness **不接纳任何** template。
- BYO harness 必须指定 `workload.command`（Substrate 不用镜像 entrypoint）。
- `env` 中 `value` 与 `credentialRef` 二选一。
- golang-adk 镜像预装基础 CLI 工具，扩展工具通过独立的 kagent-tools 服务提供（MCP 协议）。

---

## 下一步 Next

- 创建第一个 agent → [01-first-agent.md](01-first-agent.md)
- AgentTemplate 行为定义 → [03-agent-template.md](03-agent-template.md)
- ModelConfig LLM 配置 → [04-model-config.md](04-model-config.md)
- 测试与 evals → [../03-skills/04-testing.md](../03-skills/04-testing.md)
- 平台级部署 Harness → [../03-idp/01-cluster-setup.md](../03-idp/01-cluster-setup.md)