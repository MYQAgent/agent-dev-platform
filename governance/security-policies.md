# 安全策略 Security Policies

## 凭据 Credentials

- 所有 API key / token 用 Kubernetes `Secret` 引用，禁止明文进 Git 或 ModelConfig。
- `Harness.env` 敏感值用 `credentialRef`，不用 `value`。
- 定期轮换凭据。

## MCP 工具 MCP tools

- 敏感工具（写操作）设置 `requireApproval`。
- 集群访问 MCP server 优先 `--read-only`。
- `ToolBinding.tools` 白名单只暴露必要工具。

## 镜像与来源 Immutability

- 镜像、skill 来源一律 digest 引用（OCI `@sha256:`，git 完整 commit，S3 versionId）。
- 禁止生产使用可变 tag。

## RBAC

- 每团队独立 namespace，RBAC 最小权限。
- `Harness.allowedAgentTemplates.selector` 控制准入。

## 可观测 Observability

- 启用 OpenTelemetry 追踪 agent 调用链。
- 关键操作记录审计日志。
