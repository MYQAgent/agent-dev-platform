# Skill PR Review 清单

发布 skill 前逐项检查。

## 格式 Format

- [ ] `SKILL.md` 存在且位于 `skills/<name>/` 下
- [ ] `name` 与目录名一致，符合命名规范（小写/连字符，不以连字符开头结尾）
- [ ] `description` 含「做什么 + 何时用 + 关键词」
- [ ] `skills-ref validate` 通过
- [ ] `SKILL.md` < 500 行

## 内容 Content

- [ ] workflow 是显式分步骤，不是开放式描述
- [ ] 重内容在 `references/`，未堆在 SKILL.md
- [ ] 有边缘情况说明，防止误报
- [ ] 脚本输出结构化数据（JSON）

## 质量 Quality

- [ ] 有 `evals/evals.json` 且每个场景有明确期望
- [ ] evals 通过率达标（建议 ≥ 80%）
- [ ] 有测试夹具（`tests/`）

## 安全 Security

- [ ] 无硬编码 secret / API key
- [ ] 敏感工具标注 `requireApproval`
- [ ] 来源用 digest 引用（OCI `@sha256:` / git commit / S3 versionId）
