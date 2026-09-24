# 多团队工作流

> Multi-team workflows on a shared platform.

---

## 核心要点 Key points

共享平台上，每个团队自助开发，平台团队只维护基础设施。

```
平台团队（Platform team）
  ├── 维护 controller + Substrate + PostgreSQL
  ├── 提供 Harness 模板 + 命名空间 + RBAC
  └── 维护 CI/CD 流水线与治理

团队 A / B / C（App teams）
  ├── 在自己的 namespace 开发 skill
  ├── 发布 skill 为 OCI
  ├── 应用自己的 AgentTemplate
  └── 无需平台团队介入
```

---

## 命名空间隔离 Namespace isolation

```yaml
# 每团队一个 namespace，RBAC 限制在该 namespace 内
namespace: team-a
namespace: team-b
```

kagent v2 的引用是**同 namespace** 的：`AgentTemplate` 引用的 `ModelConfig`、`RemoteMCPServer`、skill 都在同一 namespace。

---

## 团队自助流程 Team self-service

```bash
# 1. 团队 fork template/agent（见 ../../template/）
# 2. 写自己的 skill
# 3. 发布 skill 为 OCI
# 4. 应用 AgentTemplate（引用团队 skill）
kubectl apply -f agenttemplate.yaml -n team-a
```

平台团队通过 `Harness.allowedAgentTemplates.selector` 决定哪些 template 可被接纳。

---

## 下一步 Next

- 脚手架 → [../../template/](../../template/)
- 平台层部署 → [../../platform/](../../platform/)
