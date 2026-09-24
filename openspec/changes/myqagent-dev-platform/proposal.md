## Why

kagent（kagent-dev/kagent）已经发布 v1.0.0-alpha3，API v2（`Harness` / `AgentTemplate` / `AgentInstance` + Substrate 运行时 + A2A 交互）基本落地。但社区缺少一套「从零集群写 skill 到自建平台」的开发者平台级指南：现有文档分散在 kagent / kmcp / fluxcd/agent-skills 三个仓库，本地 CLI 版本（v0.9.9）与最新 v2 存在 API 断裂，开发者容易被误导。

## What Changes

- 新建一套 kagent v2 开发者平台指南，覆盖从基础到 IDP 的完整学习路径。
- 文档按「上手阻力」分层（写 skill → 跑 agent → 打包发布 → 建平台），而非按主题平铺。
- 提供两个示例：`hello-agent`（最小跑通）与 `k8s-agent`（专业级，全组件 + 全链路）。
- 提供可复用脚手架（`template/`）、CI/CD 流水线（`pipelines/`）、IDP 平台层（`platform/`）与治理（`governance/`）。
- 以 fluxcd/agent-skills 作为 skill 写法的标准参照，但采用 kagent v2 原生的 OCI digest 引用分发模式，不照搬其「安装到本地目录」模型。
- 版本钉选：锁定 kagent v1.0.0-alpha3，并记录 v0.x legacy 迁移路径。
- 文档采用中英双语（中文为主，README 提供英文 TL;DR）。

## Capabilities

### New Capabilities
- `docs-basics`: 面向个人开发者的基础文档（零/低集群），涵盖写 SKILL.md、安装 CLI、v2 架构、官方镜像跑通 agent。
- `docs-intermediate`: 面向团队开发的进阶文档，涵盖 Agent Plugins 1.0.0 格式、skill 打包为 OCI、MCP 集成、Harness 四种 adapter、测试与 evals。
- `docs-idp`: 面向平台工程的 IDP 文档，涵盖集群搭建（controller + Substrate）、CI/CD、治理、多团队工作流。
- `docs-best-practices`: 参考类最佳实践，涵盖 skill 设计、安全、从 v0.x legacy 迁移。
- `examples-hello-agent`: 最小可运行的 AgentTemplate 示例。
- `examples-k8s-agent`: 专业级 Kubernetes agent 示例（3 个 skill，含 scripts/references/evals/多平台 plugin，打通「内容→打包→OCI 引用」全链路）。
- `templates`: 可复制脚手架（skill-bundle 与 agent 项目模板）。
- `pipelines`: 可复用的 GitHub Actions CI/CD 流水线。
- `platform`: IDP 平台层（helm/terraform/多团队示例）。
- `governance`: 治理与安全（review 清单、安全策略、observability）。

### Modified Capabilities
<!-- 无既有 capability 需要修改 -->

## Impact

- 新增一个完整的仓库级目录结构（`docs/`、`examples/`、`template/`、`pipelines/`、`platform/`、`governance/`）。
- 顶层 `README.md`（总索引）与 `VERSIONS.md`（版本钉选）。
- 依赖外部事实：kagent v1.0.0-alpha3 的 CRD/CLI 形态、Agent Plugins 1.0.0 规范、Substrate v0.2.0-beta5、fluxcd/agent-skills 作为 skill 写法参照。
- 无既有代码/API 被修改，不引入新运行时依赖（所有命令均为消费者侧执行）。
