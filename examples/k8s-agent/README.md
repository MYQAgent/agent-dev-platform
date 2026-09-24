# k8s-agent

专业级 Kubernetes agent 示例，展示完整的 skill 开发与分发链路。

> A production-grade Kubernetes agent example demonstrating the full skill lifecycle.

## 结构 Structure

```
k8s-agent/
├── skills/
│   ├── k8s-knowledge/       SKILL.md + references/ + evals/
│   ├── k8s-troubleshoot/    SKILL.md + scripts/ + evals/
│   └── k8s-security/        SKILL.md + references/ + evals/
├── plugin.json               Agent Plugins 1.0.0 根清单
├── .claude-plugin/           Claude Code 插件清单
├── .codex-plugin/            Codex 插件清单
├── harness.yaml              运行时适配器
├── agenttemplate.yaml        agent 行为（引用 skill + MCP）
├── modelconfig.yaml          LLM 配置
├── remotemcpserver.yaml      MCP server 引用
└── Makefile                  validate / build / push / test
```

## 用法 Usage

```bash
# 1. 校验
make validate

# 2. 打包为 OCI 并推送
make push REGISTRY=ghcr.io/my-org TAG=0.1.0

# 3. 获取 digest 后替换 agenttemplate.yaml 中的 REPLACE_WITH_DIGEST
# 4. 部署
kubectl apply -f harness.yaml -f modelconfig.yaml -f remotemcpserver.yaml -f agenttemplate.yaml
```

> 所有 `REPLACE_WITH_DIGEST` 占位符需替换为真实 OCI digest（生产环境必须用 digest 引用）。
