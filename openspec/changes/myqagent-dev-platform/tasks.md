## 1. 顶层文件

- [x] 1.1 创建 README.md（总索引 + 三条路径入口 + 版本声明，中英双语）
- [x] 1.2 创建 VERSIONS.md（版本钉选 v1.0.0-alpha3 + v0.x 迁移时间线）

## 2. Phase 1: docs/01-basics + hello-agent

- [x] 2.1 创建 docs/01-basics/01-write-skill.md（零集群写 SKILL.md + 本地校验）
- [x] 2.2 创建 docs/01-basics/02-install.md（kagent CLI + kmcp 安装，标注版本升级）
- [x] 2.3 创建 docs/01-basics/03-architecture.md（v2 架构一页图）
- [x] 2.4 创建 docs/01-basics/04-run-agent.md（官方镜像一条命令跑通）
- [x] 2.5 创建 examples/hello-agent/agenttemplate.yaml（最小可运行示例）

## 3. Phase 2: docs/02-intermediate + k8s-agent

- [x] 3.1 创建 docs/02-intermediate/01-skill-format.md（Agent Plugins 1.0.0，对照 fluxcd）
- [x] 3.2 创建 docs/02-intermediate/02-skill-bundle.md（打包 → OCI → 引用）
- [x] 3.3 创建 docs/02-intermediate/03-mcp-integration.md（RemoteMCPServer + ToolBinding）
- [x] 3.4 创建 docs/02-intermediate/04-harness.md（四种 adapter）
- [x] 3.5 创建 docs/02-intermediate/05-testing.md（evals + 测试）
- [x] 3.6 创建 examples/k8s-agent/skills/k8s-knowledge（SKILL.md + references + evals）
- [x] 3.7 创建 examples/k8s-agent/skills/k8s-troubleshoot（SKILL.md + scripts + evals）
- [x] 3.8 创建 examples/k8s-agent/skills/k8s-security（SKILL.md + references + evals）
- [x] 3.9 创建 examples/k8s-agent 的 plugin.json + 多平台清单 + agenttemplate/harness/modelconfig/remotemcpserver + Makefile

## 4. Phase 3: docs/03-idp + 04-best-practices

- [x] 4.1 创建 docs/03-idp/01-cluster-setup.md（controller + Substrate，解读 setup-cluster.sh）
- [x] 4.2 创建 docs/03-idp/02-pipelines.md（CI/CD）
- [x] 4.3 创建 docs/03-idp/03-governance.md（治理）
- [x] 4.4 创建 docs/03-idp/04-multi-team.md（多团队）
- [x] 4.5 创建 docs/04-best-practices/skill-design.md
- [x] 4.6 创建 docs/04-best-practices/security.md
- [x] 4.7 创建 docs/04-best-practices/migration.md（v0.x → v2）

## 5. Phase 4: template/ + pipelines/

- [x] 5.1 创建 template/skill-bundle（skills 目录 + plugin.json + Makefile）
- [x] 5.2 创建 template/agent（agenttemplate/harness/modelconfig/remotemcpserver 脚手架）
- [x] 5.3 创建 pipelines/skill-publish.yaml
- [x] 5.4 创建 pipelines/agent-apply.yaml
- [x] 5.5 创建 pipelines/mcp-deploy.yaml

## 6. Phase 5: platform/ + governance/

- [x] 6.1 创建 platform/helm（kagent + kmcp 引用上游 values）
- [x] 6.2 创建 platform/terraform（集群初始化）
- [x] 6.3 创建 platform/examples（多团队示例）
- [x] 6.4 创建 governance/review-checklist.md
- [x] 6.5 创建 governance/security-policies.md
- [x] 6.6 创建 governance/observability（OTEL + Grafana）
- [x] 6.7 创建根目录 Makefile（docs / docs-http / docs-mkdocs / docs-vitepress / docs-github）
- [x] 6.8 创建 docs/index.html + docs/_sidebar.md（docsify，CDN 方式）
