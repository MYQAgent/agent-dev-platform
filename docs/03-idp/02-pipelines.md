# CI/CD 流水线

> CI/CD pipelines for skill publishing and agent deployment.

---

## 核心要点 Key points

三条标准流水线（复用见 [../../pipelines/](../../pipelines/)）：

```
skill-publish    写 skill → lint → 打包 OCI → 推送 → 输出 digest
agent-apply      AgentTemplate/Harness → kubectl apply
mcp-deploy       kmcp build → 部署 MCP server
```

---

## 典型流程 Typical flow

```
开发者推送 skill 变更
      │
      ▼
GitHub Actions: skill-publish
      │  lint（skills-ref validate / shellcheck）
      │  打包（oras / flux operator）
      │  推送 ghcr.io → 得到 digest
      ▼
AgentTemplate 引用新 digest
      │
      ▼
GitHub Actions: agent-apply
      │  kubectl apply（或 dry-run 预览）
      ▼
集群更新 agent
```

---

## 关键点 Key points

- **生产必须 digest 引用**（`@sha256:...`），tag 可漂移。
- lint 用 `skills-ref validate` 校验 frontmatter，`shellcheck` 校验脚本。
- 打包可用 `oras`、`flux operator skills publish` 或 `kmcp` 任一。
- `agent-apply` 建议先用 `--dry-run` 或 GitOps（Argo CD/Flux）部署。

---

## 下一步 Next

- 治理 → [03-governance.md](03-governance.md)
- 复用流水线文件 → [../../pipelines/](../../pipelines/)
