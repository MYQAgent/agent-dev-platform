# 从 v0.x legacy 迁移到 v2

> Migrate from kagent v0.x (legacy) to v2.

---

## 核心结论 Key takeaway

**没有自动迁移。** kagent 官方明确：legacy 的 `SandboxAgent` / `Agent` / session 数据不会自动迁移，alpha 用户需重建配置与实例。

---

## 概念映射 Concept mapping

| v0.x (legacy) | v2 (v1.0.0-alpha3) |
|---------------|--------------------|
| `kagent init adk python dice` | `AgentTemplate` + `Harness` CRD |
| `SandboxAgent` / `Agent` CRD | `AgentTemplate`（行为）+ `Harness`（运行时） |
| `kagent deploy` | apply Harness/AgentTemplate |
| session / task | A2A 协议 |
| `.agents/skills/` 本地目录 | `AgentTemplate.spec.skills[].source`（OCI/git/S3） |
| `kagent add-mcp` | `RemoteMCPServer` + `ToolBinding` |
| 内建运行时 | Substrate |

---

## 迁移步骤 Migration steps

1. 记录 legacy agent 的 prompt、tools、skills、model 配置。
2. 用 v2 重建：
   - `ModelConfig` ← 原 model 配置
   - `AgentTemplate` ← 原 prompt + skills + tools
   - `Harness` ← 原运行时
   - `RemoteMCPServer` ← 原 MCP 配置
3. 用 OCI 打包 skill 并以 digest 引用。
4. 重新创建 AgentInstance（会话数据不保留）。

---

## 注意事项 Caveats

- legacy CRD（SandboxAgent/AgentHarness）在 v2 稳定后被删除。
- 升级前先在新集群验证 v2 工作流，再切换。
- 版本钉选见 [../../VERSIONS.md](../../VERSIONS.md)。
