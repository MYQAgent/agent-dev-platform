# 第一课：编写你的第一个 SKILL.md

> Lesson 1: Write your first SKILL.md — **无需 Kubernetes 集群，无需安装任何东西**。

> 成本级别：① 零依赖（编辑器 + 一个本地校验工具即可）

---

## 核心命令 Core commands

```bash
# 1. 校验 skill 格式（任选其一）
npx skills-ref validate ./skills/my-skill        # 社区参考实现
gh skill publish --dry-run                        # 若已安装 gh CLI

# 2. 仅需一个文本编辑器，创建下面的文件
```

---

## 什么是 skill？What is a skill?

skill 是一个目录，**至少包含一个 `SKILL.md`**。它给 AI agent 提供一套「何时用 + 怎么做」的指令。

```
skill-name/
├── SKILL.md          # 必需：元数据 + 指令
├── scripts/          # 可选：可执行脚本
├── references/       # 可选：按需加载的参考文档
└── assets/           # 可选：模板、资源
```

遵循 [Agent Skills 标准](https://agentskills.io/specification.md)，kagent v2 消费的也是这个格式（Agent Plugins 1.0.0）。

---

## SKILL.md 结构 Structure

`SKILL.md` = **YAML frontmatter**（元数据）+ **Markdown 正文**（指令）。

### 最小示例 Minimal example

```markdown
---
name: hello-world
description: 一个演示用 skill，当用户想了解 skill 格式时使用。
---

# Hello World Skill

你是示例 skill。当用户询问 skill 格式时，按以下步骤回答：

1. 说明 frontmatter 的 `name` 和 `description` 是必需字段。
2. 给出一个最小可运行的 SKILL.md 示例。
```

### 完整示例（含可选字段）Full example

```markdown
---
name: k8s-knowledge
description: Kubernetes 核心资源（Pod/Deployment/Service 等）的知识问答与 YAML 生成。当用户询问 Kubernetes 概念或需要生成清单时使用。
license: Apache-2.0
compatibility: Requires kubectl and access to a Kubernetes cluster
metadata:
  author: example-org
  version: "1.0"
allowed-tools: Bash(kubectl:*) Read
---
```

---

## frontmatter 字段速查 Field reference

| 字段 | 必需 | 约束 |
|------|------|------|
| `name` | ✅ | 1-64 字符，小写字母/数字/连字符，不能以连字符开头或结尾，必须与目录名一致 |
| `description` | ✅ | 1-1024 字符，说明**做什么 + 何时用**，含关键词便于 agent 识别 |
| `license` | — | 许可证名 |
| `compatibility` | — | 环境要求（如 `Requires git, docker, jq`）。若 skill 调用了 kubectl，必须注明集群访问需求，并在 workflow 中声明 context 校验。 |
| `metadata` | — | 任意键值对 |
| `allowed-tools` | — | 空格分隔的预批准工具（实验性） |

### `description` 好坏对比

```yaml
# ❌ 差：太模糊
description: Helps with Kubernetes.

# ✅ 好：做什么 + 何时用 + 关键词
description: 生成和校验 Kubernetes 清单（Pod/Deployment/Service），当用户询问
             Kubernetes 概念或需要编写 YAML 时使用。
```

---

## 分阶段加载 Progressive disclosure

Agent 按需加载 skill 内容，因此要控制大小：

```
1. 元数据 (~100 tokens)     → 所有 skill 启动时加载 name + description
2. 指令 (<5000 tokens)      → 激活 skill 时加载 SKILL.md 全文
3. 资源 (按需)              → scripts/ references/ assets/ 用到才读
```

**规则：SKILL.md 保持在 500 行以内**，重内容放到 `references/`。

---

## 校验 Validate

```bash
# 用 skills-ref（Agent Skills 参考实现）
npx skills-ref validate ./skills/my-skill
```

通过后输出类似 `valid`，未通过会指出 frontmatter 错误（如 name 含大写字母）。

---

## 下一步 Next

写好了 SKILL.md，下一步：

- 想跑起来看效果 → [04-run-agent.md](04-run-agent.md)
- 想深入了解格式规范 → [../02-intermediate/01-skill-format.md](../02-intermediate/01-skill-format.md)
