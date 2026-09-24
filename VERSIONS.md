# 版本钉选 · Version Pinning

本指南所有命令与示例基于 **kagent v1.0.0-alpha3**（2026-09-24 发布）。

## 版本时间线 Version Timeline

| 版本 | 状态 | 说明 |
|------|------|------|
| v0.9.9 | ❌ 弃用（legacy） | 旧 `SandboxAgent` / `Agent` CRD 与 `kagent init adk python dice` 工作流，API v2 落地后被删除 |
| v0.10.x | ⚠️ 过渡 | legacy 与 v2 并存，仅建议已有用户 |
| **v1.0.0-alpha3** | ✅ **本指南基准** | API v2 基本落地：`Harness` / `AgentTemplate` / `AgentInstance` |
| v1.0.0 GA | 🔜 未来 | 跟踪点，见下文 |

## 核心 API 变化 v0.9.9 → v1.0.0-alpha3

| 概念 | v0.9.9 (legacy) | v1.0.0-alpha3 (v2) |
|------|-----------------|-------------------|
| 创建项目 | `kagent init adk python dice` | `AgentTemplate` + `Harness` CRD |
| agent 资源 | `SandboxAgent` / `Agent` CRD | `AgentInstance`（PostgreSQL + gRPC，非 K8s CRD） |
| 部署 | `kagent deploy` | apply Harness/AgentTemplate CRD |
| MCP | `kagent add-mcp` | `RemoteMCPServer` CRD + `ToolBinding` |
| skill 加载 | `.agents/skills/` 本地目录 | `AgentTemplate.spec.skills[].source`（OCI/git/S3） |
| 运行时 | 控制器内建 | **Substrate**（唯一 compute backend） |
| 交互 | session/task | **A2A** 协议 |

## 检查本地版本 Check your version

```bash
kagent version
# 期望输出含 kagent_version: "1.0.0-alpha3"
# 若是 "0.9.9"，需要升级：
```

升级到 v1.0.0-alpha3：

```bash
# 从 GitHub Release 下载对应平台二进制
# https://github.com/kagent-dev/kagent/releases/tag/v1.0.0-alpha3
# 例如 linux-amd64：
curl -fsSL -o /usr/local/bin/kagent \
  https://github.com/kagent-dev/kagent/releases/download/v1.0.0-alpha3/kagent-linux-amd64
chmod +x /usr/local/bin/kagent
```

## 未来跟踪 Tracking

- kagent 仍处于 alpha，CRD 与 CLI 可能继续演进。
- 稳定版（GA）发布后，应更新本仓库示例并重跑验证。
- 迁移遗留 agent 的要点见 [docs/04-best-practices/migration.md](docs/04-best-practices/migration.md)。
