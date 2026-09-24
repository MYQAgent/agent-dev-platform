# skill 设计最佳实践

> Best practices for designing skills.

---

## 核心原则 Principles

| 原则 | 说明 |
|------|------|
| 职责单一 | 一个 skill 只做一件事（知识 / 审计 / 调试 分开） |
| workflow 显式 | 分阶段步骤，非开放式描述 |
| reference 按需加载 | SKILL.md < 500 行，重内容放 references/ |
| 边缘情况处理 | 防止常见模式误报 |
| 脚本输出结构化 | JSON 输出，优先调 CLI 而非 ad-hoc 解析 |

---

## 结构模板 Structure template

```
skill-name/
├── SKILL.md          # frontmatter + workflow（<500 行）
├── scripts/          # 辅助脚本（输出 JSON）
├── references/       # 清单/查找表（按需加载）
├── assets/           # 模板/资源
└── evals/evals.json  # 评估场景
```

---

## description 写法 Writing description

```yaml
# ❌ 差
description: Helps with Kubernetes.

# ✅ 好：做什么 + 何时用 + 关键词
description: 生成和校验 Kubernetes 清单，当用户询问 Kubernetes 概念或编写 YAML 时使用。
```

---

## 渐进披露 Progressive disclosure

```
元数据（~100 tokens）   → 启动加载
指令（<5000 tokens）     → 激活加载
资源（按需）             → 用到才读
```

---

## 反模式 Anti-patterns

- ❌ 一个 skill 包罗万象 → ✅ 按职责拆分
- ❌ SKILL.md 写成长篇教程 → ✅ 精简，细节入 references/
- ❌ 脚本输出人类可读文本 → ✅ 输出 JSON 供解析
- ❌ 忽略边缘情况 → ✅ 显式说明边界与误报规避
