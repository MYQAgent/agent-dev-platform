# k8s-agent 完整案例

> 专业级 Kubernetes agent 示例，展示完整的 skill 开发与分发链路。  
> 代码位置：`examples/k8s-agent/`

---

## 包含的文件

| 文件 | 类型 | 说明 | 相关文档 |
|------|------|------|---------|
| `harness.yaml` | Harness CRD | 运行时配置（kagent adapter） | [02-harness.md](02-harness.md) |
| `agenttemplate.yaml` | AgentTemplate CRD | agent 行为：4 个 skill + MCP 工具 | [03-agent-template.md](03-agent-template.md) |
| `modelconfig.yaml` | ModelConfig CRD | LLM 配置（OpenAI / DeepSeek） | [04-model-config.md](04-model-config.md) |
| `remotemcpserver.yaml` | RemoteMCPServer CRD | MCP 工具服务引用 | [MCP 集成](../03-skills/03-mcp-integration.md) |
| `plugin.json` | 插件清单 | Agent Plugins 1.0.0 根清单 | [Skill 格式](../03-skills/01-skill-format.md) |
| `Makefile` | 构建脚本 | validate → oras push → test | [工具链安装](../03-skills/00-toolchain.md) |

### 额外平台支持（可选）

| 目录 | 说明 |
|------|------|
| `.claude-plugin/` | Claude Code 市场发布清单 |
| `.codex-plugin/` | OpenAI Codex 市场发布清单 |

---

## 4 个 Skill

| Skill | 功能 | 关键文件 |
|-------|------|---------|
| `k8s-knowledge` | K8s 核心资源知识问答 + YAML 清单生成 | `references/resource-cheatsheet.md` |
| `k8s-troubleshoot` | 集群故障排查：Pod 崩溃、调度失败、镜像拉取错误 | `scripts/diagnose.sh` |
| `k8s-security` | 安全审计：RBAC、Secret、容器安全、deprecated API | `references/security-checklist.md` |
| `k8s-cluster-context` | 多集群 context 管理：确认目标集群、检测冲突 | `scripts/check-context.sh` |

> `k8s-cluster-context` 被其他三个 skill 依赖（所有 kubectl 命令前都要执行 `check-context.sh` 校验目标集群）。

---

## 完整构建流程

```bash
# 1. 启动本地 registry（make create-k3d-cluster 已内置）
# 2. 校验 SKILL.md 格式
npx skills-ref validate skills/k8s-knowledge

# 3. 打包所有 skill 为 OCI artifact 并推送
oras push localhost:5000/my-org/k8s-skills:0.1.0 ./skills

# 4. 获取 digest
oras manifest fetch localhost:5000/my-org/k8s-skills:0.1.0 | jq -r '.digest'

# 5. 将 digest 填入 agenttemplate.yaml 的 REPLACE_WITH_DIGEST
# 6. 部署到集群
kubectl apply -f harness.yaml -f modelconfig.yaml -f remotemcpserver.yaml -f agenttemplate.yaml
```

> 详细说明见 [打包 OCI 并引用](../03-skills/02-skill-bundle.md)。

---

## 目录结构

```
examples/k8s-agent/
├── skills/
│   ├── k8s-knowledge/        SKILL.md + references/ + evals/
│   ├── k8s-troubleshoot/     SKILL.md + scripts/ + evals/
│   ├── k8s-security/         SKILL.md + references/ + evals/
│   └── k8s-cluster-context/  SKILL.md + scripts/ + references/ + evals/
├── .claude-plugin/           Claude Code 市场清单
├── .codex-plugin/            Codex 市场清单
├── harness.yaml              运行时适配器
├── agenttemplate.yaml        agent 行为定义
├── modelconfig.yaml          LLM 配置
├── remotemcpserver.yaml      MCP 服务引用
├── plugin.json               Agent Plugins 根清单
├── Makefile                  构建脚本
└── README.md                 本示例说明
```

---

## 下一步 Next

- 工具链安装 → [../03-skills/00-toolchain.md](../03-skills/00-toolchain.md)
- Skill 格式详解 → [../03-skills/01-skill-format.md](../03-skills/01-skill-format.md)
- OCI 打包详解 → [../03-skills/02-skill-bundle.md](../03-skills/02-skill-bundle.md)