# 安全最佳实践

> Security best practices for agent development.

---

## 核心清单 Checklist

| 类别 | 措施 |
|------|------|
| Secret | API key 用 `Secret` 引用，绝不明文进 Git / ModelConfig |
| MCP 授权 | 敏感工具用 `requireApproval` |
| 集群访问 | MCP server 用 `--read-only` |
| 镜像 | 生产用 digest 引用（`@sha256:...`） |
| RBAC | 最小权限，namespace 隔离 |

---

## Secret 处理 Secret handling

```yaml
# ❌ 明文
apiKey: sk-abc123

# ✅ Secret 引用
apiKey:
  secretRef:
    name: openai-credentials
    key: apiKey
```

Harness env 同理：`value` 与 `credentialRef` 二选一，敏感值用后者。

---

## MCP 工具授权 MCP tool authorization

```yaml
spec:
  tools:
    - mcp:
        server: { kind: RemoteMCPServer, name: k8s-mcp }
        tools: ["get_pods"]        # 只暴露只读工具
        requireApproval: true      # 每次调用前批准
```

---

## 镜像与来源 Immutability

- 镜像、skill 来源都用 digest（OCI `@sha256:`，git 完整 commit，S3 versionId）
- 防止 tag 漂移导致内容被篡改

---

## 完整清单

见 [../../governance/security-policies.md](../../governance/security-policies.md)。
