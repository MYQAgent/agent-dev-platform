# kagent v2 架构一页图

> Architecture in one page — 成本级别 ①（纯理解）

---

## 全景图 Big picture

```
┌─────────────────────────────────────────────────────────────┐
│                      kagent v2 (v1.0.0-alpha3)              │
│                                                             │
│  ┌─────────────┐     ┌──────────────────────┐               │
│  │  Harness    │     │   AgentTemplate      │               │
│  │  运行时适配器 │────▶│   agent 行为定义      │               │
│  │  kagent/    │  编译 │   prompt + tools     │               │
│  │  codex/     │      │   + skills + plugins │               │
│  │  claude/    │      └──────────┬───────────┘               │
│  │  byo        │                 │ 引用                       │
│  └─────────────┘                 ▼                           │
│                        ┌──────────────────────┐              │
│                        │  AgentInstance       │  ← 非 K8s     │
│                        │  (PostgreSQL + gRPC) │    资源       │
│                        └──────────┬───────────┘              │
│                                   │ A2A 协议                  │
│                                   ▼                           │
│                        ┌──────────────────────┐              │
│                        │  Substrate (运行时)   │  ← 唯一      │
│                        │  Actors              │    backend   │
│                        └──────────────────────┘              │
│                                                             │
│  ┌─────────────┐     ┌──────────────────────┐               │
│  │ ModelConfig │     │  RemoteMCPServer     │               │
│  │  LLM 配置    │     │  MCP server 引用      │               │
│  └─────────────┘     └──────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## 核心概念速查 Concepts

| 概念 | 类型 | 作用 | 关键点 |
|------|------|------|--------|
| `Harness` | K8s CRD | 运行时适配器 | kagent/codex/claude/byo 四选一，含镜像 + Substrate 策略 |
| `AgentTemplate` | K8s CRD | agent 行为 | prompt + tools + skills + plugins，**可移植** |
| `AgentInstance` | gRPC 资源 | 可运行的 agent 实例 | PostgreSQL 后端，A2A 交互，**不是 CRD** |
| `ModelConfig` | K8s CRD | LLM 配置 | 模型 provider + 凭据 |
| `RemoteMCPServer` | K8s CRD | MCP server 引用 | agent 通过 ToolBinding 引用 |
| Substrate | 外部系统 | 计算后端 | 唯一 backend，Actors 承载运行时 |

---

## 关键心智模型 Mental models

### 1. 「Harness × AgentTemplate = 一对」

```
Harness（怎么跑）      AgentTemplate（跑什么）
    │                        │
    └──────────┬─────────────┘
               ▼
         AgentInstance（一个可对话的 agent）
```

一个 AgentTemplate 需被某个 Harness 的 `allowedAgentTemplates.selector` 接纳才会编译。

### 2. 三层分离

```
行为（AgentTemplate）    ← 你主要写这个
  ↓
运行时（Harness → Substrate）  ← 平台团队配这个
  ↓
交互（AgentInstance / A2A）    ← 用户通过这个对话
```

### 3. skill 是「引用」不是「安装」

```
AgentTemplate.spec.skills:
  - name: k8s-knowledge
    source:
      oci: ghcr.io/my-org/k8s-skills@sha256:...   # 直接引用 OCI digest
```

与 fluxcd 的「安装到本地目录」不同，v2 直接引用不可变来源。

---

## 下一步 Next

- 跑通一个 agent → [04-run-agent.md](04-run-agent.md)
- 深入 skill 格式 → [../02-intermediate/01-skill-format.md](../02-intermediate/01-skill-format.md)
