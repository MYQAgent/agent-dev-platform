# k8s-agent

专业级 Kubernetes agent 示例，展示完整的 skill 开发与分发链路。

> 操作说明已迁移到 [docs/02-agents/05-k8s-agent-example.md](../../docs/02-agents/05-k8s-agent-example.md)。

## 目录结构

```
k8s-agent/
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
└── README.md                 本说明
```

## 入口

- [完整案例文档](../../docs/02-agents/05-k8s-agent-example.md)
- [工具链安装](../../docs/03-skills/00-toolchain.md)
- [Skill 格式](../../docs/03-skills/01-skill-format.md)
- [OCI 打包](../../docs/03-skills/02-skill-bundle.md)