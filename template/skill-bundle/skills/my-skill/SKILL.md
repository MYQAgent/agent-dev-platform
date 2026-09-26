---
name: my-skill
description: >
  在此描述 skill 做什么（what）以及何时使用（when），包含关键词便于 agent 识别。
  例如：生成和校验 XXX 清单，当用户询问 XXX 概念或需要编写 YAML 时使用。
license: Apache-2.0
compatibility: Requires <tool> and access to <resource>
metadata:
  author: your-org
  version: "1.0"
allowed-tools: Bash(<tool>:*) Read
---

# My Skill

在此描述 skill 的角色与职责。

**规则：**
- 生成内容前先核对关键约束（API 版本、字段名等）。
- 需要细节时加载 `references/` 下的文件，不要凭空发挥。
- **若 skill 调用了 kubectl，所有命令必须使用 `--context <cluster>` 显式指定目标集群，并在 workflow 开头添加 context 校验步骤。**

## 工作流 Workflow

1. 第一步：...
2. 第二步：...
3. 第三步：...

## 决策树 Decision tree

- **场景 A** → 用方法 X
- **场景 B** → 用方法 Y

## 边缘情况 Edge cases

- 情况 1：应如何处理
- 情况 2：应如何处理
