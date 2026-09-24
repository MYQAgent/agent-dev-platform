# Skill Bundle 模板

可复制的 skill 库脚手架。复制后填入自己的 skill 即可发布为 OCI。

## 用法

```bash
# 1. 复制模板
cp -r template/skill-bundle my-skills

# 2. 修改 skills/my-skill/SKILL.md（或新增 skill 目录）
# 3. 校验
make validate

# 4. 打包发布
make push REGISTRY=ghcr.io/my-org TAG=0.1.0
```

## 结构

```
skill-bundle/
├── skills/my-skill/
│   ├── SKILL.md
│   ├── scripts/
│   ├── references/
│   └── evals/evals.json
├── plugin.json
└── Makefile
```
