## Context

kagent 已发布 v1.0.0-alpha3，API v2 基本落地。核心事实（已核实）：

- CRD（`kagent.dev/v1alpha3`）：`Harness`（运行时适配器，kagent/Codex/Claude/BYO 四选一）、`AgentTemplate`（agent 行为：prompt + tools + skills + plugins）、`ModelConfig`、`RemoteMCPServer`。
- `AgentInstance` 是 PostgreSQL 后端 + gRPC 资源（A2A 交互），不是 K8s CRD。
- 运行时唯一 backend 是 Substrate（v0.2.0-beta5）。
- skill 遵循 Agent Plugins 1.0.0：`SKILL.md` + `plugin.json`，`AgentTemplate.spec.skills[].source` 支持 OCI digest / git commit / S3 三种来源。
- 本地已装 CLI 为 v0.9.9（legacy，将被删除），与 v2 有 API 断裂。

本地开发环境有两条路径：消费者路径（官方镜像 + Helm，一条命令）、贡献者路径（`setup-cluster.sh` 十步，含 Substrate + kubectl-ate + CA/JWT pool + 构建镜像）。

## Goals / Non-Goals

**Goals:**
- 提供从「零集群写 skill」到「自建平台」的分层指南。
- 文档按上手阻力排序，每篇 cheat sheet 风格（1-2 屏），中英双语。
- `hello-agent` 最小跑通 + `k8s-agent` 专业级全链路示例。
- 复用脚手架、CI/CD、平台层、治理沉淀。

**Non-Goals:**
- 不实现新的 kagent CLI 或框架（复用现有 kagent CLI + kmcp）。
- 不照搬 fluxcd/agent-skills 的「安装到本地目录」模型（v2 已用原生 OCI digest 引用取代）。
- 首期不维护独立 helm/terraform 的深度定制（`platform/` 引用上游 + 少量 values，不 fork 上游 chart）。
- 不写从零的 K8s 领域知识库内容（k8s-agent 的 references 为精简速查，非全量手册）。

## Decisions

### D1: 按「上手阻力」分层，不按主题平铺
学习成本从 ①写 skill（零依赖）→ ⑥建 IDP（最重）。文档严格按此排序，让读者一眼判断「这篇要不要现在看」。
- 替代方案：主题平铺（install→concept→skill→mcp→publish→idp），会把零门槛的写 skill 埋在中间。否决。

### D2: skill 开发与 agent 运行解耦
写 SKILL.md 不需要集群；跑 agent 才需要 Substrate。第一课是「编辑器写 SKILL.md 并本地校验」，Substrate 复杂度推迟到 `03-idp`。
- 理由：这是「快速上手」目标的关键；`01-basics` 因此可做到零集群。

### D3: skill 分发用 v2 原生 OCI 引用
`AgentTemplate.spec.skills[].source.oci` 直接 digest 引用，不做独立 install 步骤。
- 替代方案：保留 fluxcd 式「安装到 `.agents/skills/` 本地目录」的便利路径。不采纳，因 v2 设计已内建引用，增加一条并行路径会造成概念混乱。

### D4: 版本钉选 v1.0.0-alpha3
所有示例/命令基于 v1.0.0-alpha3，`VERSIONS.md` 记录 v0.9.9（弃用）→ v1.0.0-alpha3（v2）→ 未来稳定版跟踪点。
- 理由：本机旧 CLI 会误导读者，必须显式钉选并警告。

### D5: 文档中英双语
中文为主，代码/命令/术语保留英文，README 加英文 TL;DR。
- 理由：团队/社区受众中文为主，但命令和术语需原样保留以可执行。

### D6: k8s-agent 示例专业级
3 个 skill（k8s-knowledge / k8s-troubleshoot / k8s-security），含 scripts / references / evals / 多平台 plugin（.claude-plugin + .codex-plugin），打通「内容→打包→OCI 引用」全链路。
- 理由：用户明确要求「以专业为主必须为主」，示例需展示生产组件全貌。

## Risks / Trade-offs

- [kagent v1.0.0-alpha3 是 alpha 版本，CRD/CLI 可能继续演进] → VERSIONS.md 显式钉选版本，docs 中标注「基于 alpha3，未来可能变动」，并在 best-practices 提供迁移章节。
- [Substrate 环境搭建复杂（CA/JWT pool 等）] → 通过 D2 解耦，消费者路径用官方镜像避开；仅在 `03-idp` 深入。
- [示例中的 OCI digest 引用需真实 registry 才能端到端验证] → 示例提供「本地 registry（localhost:5001）+ Makefile」路径，文档标注 digest 占位符需替换。
- [文档量大（中英双语 × 多层）] → cheat sheet 风格控制每篇 1-2 屏，英文用 TL;DR/要点而非全文对照，避免篇幅翻倍。
- [上游 fluxcd/agent-skills 与 kagent 的 skill 格式细节差异] → docs 中明确「格式标准 vs 分发模型」的区分，避免读者混淆。

## Migration Plan

无需部署/回滚（纯文档 + 示例仓库）。落地为 Phase 递进：
- Phase 1 docs/01-basics + hello-agent（最小闭环）
- Phase 2 docs/02-intermediate + k8s-agent（核心）
- Phase 3 docs/03-idp + 04-best-practices
- Phase 4 template/ + pipelines/
- Phase 5 platform/ + governance/
- 顶层 README.md + VERSIONS.md

## Open Questions

- 是否需要随 kagent 后续稳定版（v1.0.0 GA）持续跟踪更新？→ 暂以 VERSIONS.md 记录跟踪点，不设自动更新机制。
- `platform/helm` 是否维护 fork 还是纯引用上游？→ 首期纯引用上游 + values 覆盖，后续按需 fork。
