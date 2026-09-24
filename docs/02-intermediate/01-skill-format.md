# Agent Plugins 1.0.0 格式（对照 fluxcd）

> The Agent Plugins 1.0.0 format — kagent v2 消费的 skill 格式，与 fluxcd/agent-skills 的写法同源。

---

## 核心要点 Key points

```bash
skill 目录结构：
  skill-name/
  ├── SKILL.md          # 必需：frontmatter + 指令
  ├── scripts/          # 可选：可执行脚本
  ├── references/       # 可选：按需加载的参考
  └── assets/           # 可选：模板/资源

skill bundle 根清单：
  plugin.json           # Agent Plugins 1.0.0 根清单
```

---

## fluxcd 对照 fluxcd reference

fluxcd/agent-skills 是 skill 写法的标准参照：

```
fluxcd/agent-skills/                    kagent v2 消费方式
─────────────────────                   ──────────────────
skills/<name>/SKILL.md      ──────▶     AgentTemplate.spec.skills[].source
skills/<name>/scripts/                  （OCI/git/S3 直接引用）
skills/<name>/references/
.claude-plugin/marketplace.json  ──▶    plugin.json（Agent Plugins 1.0.0）
.mcp.json                        ──▶    RemoteMCPServer CRD
```

**关键区别：分发模型**

| | fluxcd | kagent v2 |
|---|--------|-----------|
| 安装 | `flux operator skills install` → 本地目录 | 无独立 install，直接 OCI digest 引用 |
| 载体 | OCI artifact（ghcr.io） | `AgentTemplate.spec.skills[].source` |
| 消费 | agent 从 `.agents/skills/` 加载 | runtime 拉取 OCI 校验后加载 |

**相同之处：skill 内容格式完全一致**——SKILL.md 的 frontmatter（name/description）和目录结构（scripts/references/assets）两边通用。

---

## SKILL.md frontmatter

```yaml
---
name: k8s-knowledge          # 必须与目录名一致
description: >               # 做什么 + 何时用，含关键词
  Kubernetes 核心资源的知识问答与 YAML 生成。
  当用户询问 Kubernetes 概念或需要生成清单时使用。
license: Apache-2.0
compatibility: Requires kubectl and access to a Kubernetes cluster
metadata:
  author: example-org
  version: "1.0"
allowed-tools: Bash(kubectl:*) Read
---
```

完整字段约束见 [01-write-skill.md](../01-basics/01-write-skill.md)。

---

## 正文编写指南 Body guidelines

参考 fluxcd 的写法惯例：

1. **workflow 显式分阶段**，不是开放式描述
2. **reference 是可执行的清单/查找表**，不是教程
3. **边缘情况章节**防止误报
4. **脚本输出结构化数据（JSON）**，优先调 CLI 而非 ad-hoc 解析
5. **SKILL.md < 500 行**，重内容放 references/

示例见 [examples/k8s-agent](../../examples/k8s-agent/)。

---

## plugin.json 根清单 plugin.json manifest

```json
{
  "name": "k8s-skills",
  "version": "0.1.0",
  "skills": [
    "./skills/k8s-knowledge",
    "./skills/k8s-troubleshoot",
    "./skills/k8s-security"
  ]
}
```

kagent v2 通过 `AgentTemplate.spec.plugins[]` 引用打包好的 plugin bundle：

```yaml
spec:
  plugins:
    - source:
        oci: "ghcr.io/my-org/k8s-skills@sha256:..."
      skills: ["k8s-knowledge", "k8s-troubleshoot"]
```

---

## 下一步 Next

- 打包为 OCI 并引用 → [02-skill-bundle.md](02-skill-bundle.md)
- 测试与 evals → [05-testing.md](05-testing.md)
