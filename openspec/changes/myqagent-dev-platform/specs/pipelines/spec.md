## ADDED Requirements

### Requirement: 可复用 CI/CD 流水线
系统 SHALL 提供可复用的 GitHub Actions 流水线（skill-publish、agent-apply、mcp-deploy）。

#### Scenario: 复用流水线
- **WHEN** 团队将 pipelines/ 下的 workflow 复制到自己的仓库
- **THEN** 获得 skill 构建发布、agent 部署、MCP 部署的自动化能力
