# OCI Registry mirror（可选）

内部 OCI mirror，用于加速镜像拉取与隔离外部依赖。

## 结构

```
registry/
├── values.yaml          # Harbor / Zot / registry mirror 配置
└── README.md
```

## 建议

- 小团队：直接用 ghcr.io，无需 mirror。
- 大规模 / 离线环境：部署 Zot 或 Harbor 作为 pull-through cache。

> 此目录为可选占位，具体方案依赖组织的镜像策略。
