# 打包 skill 为 OCI 并引用

> Package skills as OCI and reference them from AgentTemplate.

---

## 核心命令 Core commands

```bash
# 1. 校验
npx skills-ref validate ./skills/k8s-knowledge

# 2. 打包 skill 目录为 OCI 并推送
#    （用任意 OCI 工具，示例用 oras 或 flux operator）
oras push ghcr.io/my-org/k8s-skills:v0.1.0 ./skills

# 3. 在 AgentTemplate 中引用 digest
kubectl apply -f agenttemplate.yaml
```

---

## 完整链路 Full chain

```
写 SKILL.md（编辑器）
      │
      ▼
校验（skills-ref / gh skill publish --dry-run）
      │
      ▼
打包成 OCI artifact（oras / flux operator / kmcp）
      │
      ▼
推送 registry 得到 digest
      │
      ▼
AgentTemplate.spec.skills[].source.oci 引用 digest
      │
      ▼
kagent runtime 拉取 + 校验 + 加载 skill
```

---

## 三种 skill 来源 Three sources

`AgentTemplate.spec.skills[].source` 支持三种不可变来源：

```yaml
# 1. OCI（推荐）
skills:
  - name: k8s-knowledge
    source:
      oci: "ghcr.io/my-org/k8s-skills@sha256:64位digest"

# 2. Git（完整 commit）
skills:
  - name: k8s-knowledge
    source:
      git:
        url: "https://github.com/my-org/k8s-skills"
        commit: "完整40位commit"
      path: "skills/k8s-knowledge"

# 3. S3（对象版本）
skills:
  - name: k8s-knowledge
    source:
      bucket:
        s3:
          endpoint: "https://s3.example.com"
          bucket: "skills"
          key: "k8s-skills/k8s-knowledge"
          versionId: "版本ID"
```

> 三种来源**互斥**，`path` 必须相对路径且不含 `..`。

---

## 通过 plugin bundle 引用 Referencing via plugin bundle

多个 skill 打包成一个 plugin（含 plugin.json）：

```yaml
# AgentTemplate.spec.plugins
spec:
  plugins:
    - source:
        oci: "ghcr.io/my-org/k8s-skills@sha256:..."
      skills: ["k8s-knowledge", "k8s-troubleshoot"]
```

`skills` 为空则启用 bundle 中全部 skill。

---

## 本地开发便利路径 Local dev shortcut

本地 registry（`localhost:5001`）供开发调试，避免每次推公共 registry：

```bash
# 推本地 registry
oras push localhost:5001/k8s-skills:dev ./skills

# AgentTemplate 引用
source:
  oci: "localhost:5001/k8s-skills:dev"
```

> 生产环境**必须用 digest 引用**（`@sha256:...`），tag 可被覆盖导致内容漂移。

---

## 下一步 Next

- MCP 工具集成 → [03-mcp-integration.md](03-mcp-integration.md)
- 完整示例 → [../../examples/k8s-agent/](../../examples/k8s-agent/)
