# AgentTemplate 行为定义

> AgentTemplate describes what an agent does — prompt, skills, tools, and plugins.

---

## 一句话理解

**AgentTemplate 是 agent 的"行为定义书"**——描述 agent 跑什么：用什么人格、有哪些技能、能调哪些工具。

与 Harness 的关系：

```
Harness（怎么跑） × AgentTemplate（跑什么） = AgentInstance（可对话的 agent）
     │                       │
     └──────────┬────────────┘
                ▼
         AgentInstance（一个可对话的 agent 实例）
```

---

## 完整 YAML 拆解 Full YAML breakdown

```yaml
apiVersion: kagent.dev/v1alpha3
kind: AgentTemplate
metadata:
  name: k8s-agent                # agent 名称
  namespace: kagent
  labels:
    kagent.dev/harness: k8s-agent  # 必须匹配 Harness 的 selector
spec:
  description: >                 # 一句话描述 agent 职责
    Kubernetes engineering agent with knowledge, troubleshooting,
    and security skills.

  systemPrompt: |                # agent 人格指令
    You are a Kubernetes engineering assistant.
    Route requests to the appropriate skill...

  modelConfig:                   # 引用 ModelConfig（LLM 配置）
    name: my-model-config

  skills:                        # 引用的技能（OCI/git/S3）
    - name: k8s-knowledge
      source:
        oci: ghcr.io/my-org/k8s-skills@sha256:<digest>
    - name: k8s-troubleshoot
      source:
        oci: ghcr.io/my-org/k8s-skills@sha256:<digest>

  tools:                         # MCP 工具绑定
    - mcp:
        server:
          kind: RemoteMCPServer
          name: kagent-tool-server
          tools: ["kubectl_get", "helm_list"]  # 可选：限制暴露哪些

  plugins:                       # 可选：plugin bundle
    - source:
        oci: ghcr.io/my-org/my-plugin@sha256:<digest>
      skills: ["my-skill"]
```

---

## 各字段说明 Field details

| 字段 | 必填 | 说明 |
|------|------|------|
| `metadata.labels` | ✅ | 必须匹配 Harness 的 `allowedAgentTemplates.selector`，否则不被接纳 |
| `spec.description` | ✅ | 一句话描述，UI 显示用 |
| `spec.systemPrompt` | ✅ | agent 人格和行为指令 |
| `spec.modelConfig.name` | ✅ | 引用已创建的 ModelConfig |
| `spec.skills[].source` | ❌ | 技能来源（OCI/git/S3），digest 引用 |
| `spec.tools[]` | ❌ | MCP 工具绑定，引用 RemoteMCPServer |
| `spec.tools[].mcp.tools` | ❌ | 限制暴露哪些工具，空=全部暴露 |
| `spec.plugins[]` | ❌ | Plugin bundle 引用 |

> **skill 引用必须用 digest（`@sha256:...`）**，不要用 tag。不可变引用确保每次拉取内容一致。

---

## 编译条件 Compilation conditions

AgentTemplate 被 Harness 接纳后，经历四个检查阶段。用以下命令查看：

```bash
kagent get agent-template <name>
kagent get agent-template <name> -o json
```

| Condition | 含义 | 失败常见原因 |
|-----------|------|------------|
| `Accepted` | Harness 的 selector 是否匹配 | label 不匹配 |
| `ResolvedRefs` | ModelConfig / 工具引用是否存在 | ModelConfig 名写错 |
| `Compatible` | 配置是否适合该 Harness 运行时 | 不支持的 provider |
| `Ready` | 编译已完成 | 镜像 digest 无效 |

---

## 示例 Examples

### 最小示例（无 skill / 无 tool）

```yaml
apiVersion: kagent.dev/v1alpha3
kind: AgentTemplate
metadata:
  name: my-first-agent
  namespace: kagent
  labels:
    kagent.dev/harness: my-harness
spec:
  description: My first kagent agent
  modelConfig:
    name: my-model-config
  systemPrompt: You are a concise, helpful assistant.
```

### 完整示例（含 skill + tool）

```yaml
apiVersion: kagent.dev/v1alpha3
kind: AgentTemplate
metadata:
  name: k8s-agent
  namespace: kagent
  labels:
    kagent.dev/harness: k8s-agent
spec:
  modelConfig:
    name: default-model-config
  description: Kubernetes engineering agent
  systemPrompt: |
    You are a Kubernetes engineering assistant.
    Route requests to the appropriate skill.
  skills:
    - name: k8s-knowledge
      source:
        oci: "ghcr.io/example/k8s-skills@sha256:REPLACE_WITH_DIGEST"
    - name: k8s-troubleshoot
      source:
        oci: "ghcr.io/example/k8s-skills@sha256:REPLACE_WITH_DIGEST"
  tools:
    - mcp:
        server:
          kind: RemoteMCPServer
          name: k8s-mcp
```

---

## 关键提醒 Reminders

- **label 必须匹配** Harness 的 `allowedAgentTemplates.selector`，否则 AgentTemplate 不会被接纳，永远 `Accepted=False`。
- **digest 引用**：skill 和 plugin 的 OCI 地址必须用 `@sha256:...`，不可用 tag。
- **tools 安全**：不指定 `tools[]` 过滤列表时，所有 MCP 工具对 agent 可见。生产环境建议按最小权限原则限制。

---

## 下一步 Next

- 创建第一个 agent → [01-first-agent.md](01-first-agent.md)
- 配置 LLM → [04-model-config.md](04-model-config.md)
- 深入 skill 格式 → [../03-skills/01-skill-format.md](../03-skills/01-skill-format.md)
- 架构全景 → [../01-basics/03-architecture.md](../01-basics/03-architecture.md)