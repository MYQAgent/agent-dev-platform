# Pipelines 复用流水线

可复用的 GitHub Actions 流水线。

## 文件 Files

| 文件 | 用途 |
|------|------|
| `skill-publish.yaml` | skill → lint → 打包 OCI → 推送 |
| `agent-apply.yaml` | AgentTemplate/Harness → kubectl apply（含 dry-run） |
| `mcp-deploy.yaml` | kmcp build → 部署 MCP server |

## 用法 Usage

复制到你的仓库 `.github/workflows/` 下，配置 secrets（GITHUB_TOKEN / KUBECONFIG）即可。
