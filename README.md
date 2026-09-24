# MYQAgent 开发平台 · MYQAgent Dev Platform

一套从「零集群写 skill」到「自建平台」的 kagent v2 开发者指南。

> A developer guide for building AI agents on [kagent](https://github.com/kagent-dev/kagent) (Kubernetes-native AI agent framework), from writing your first skill to running a full platform.

---

## 这是什么？ What is this?

kagent 是 CNCF 的 Kubernetes 原生 AI agent 框架。本仓库是一份**开发者平台级指南**，帮助你：

1. **零集群**学会写 agent skill（符合 Agent Plugins 1.0.0 标准）
2. **一条命令**在本地跑通 agent（官方镜像 + Helm）
3. **打通链路**把 skill 打包为 OCI 并被 `AgentTemplate` 引用
4. **逐级深入**直到自建多团队 IDP 平台

skill 写法以 [fluxcd/agent-skills](https://github.com/fluxcd/agent-skills) 作为标准参照。

---

## 快速开始 Quick Start

| 你的目标 | 从这里开始 | 成本 |
|---------|-----------|------|
| 只是想学怎么写 skill | [docs/01-basics/01-write-skill.md](docs/01-basics/01-write-skill.md) | 零集群 |
| 想跑通一个 agent | [docs/01-basics/04-run-agent.md](docs/01-basics/04-run-agent.md) | 官方镜像 |
| 想发布 skill 给团队 | [docs/02-intermediate/02-skill-bundle.md](docs/02-intermediate/02-skill-bundle.md) | 需 registry |
| 想建平台 | [docs/03-idp/01-cluster-setup.md](docs/03-idp/01-cluster-setup.md) | 需 Substrate |

---

## 目录结构 Structure

```
myqagent-dev-platform/
├── docs/              分层文档（中英双语，cheat sheet 风格）
│   ├── 01-basics/      【基本】个人开发者（零/低集群）
│   ├── 02-intermediate/【进阶】团队开发
│   ├── 03-idp/         【IDP】平台工程
│   └── 04-best-practices/ 参考
├── examples/
│   ├── hello-agent/    最小可运行示例
│   └── k8s-agent/      专业级 Kubernetes agent（全链路）
├── template/           可复用脚手架
├── pipelines/          复用 CI/CD
├── platform/           IDP 平台层（helm/terraform）
└── governance/         治理与安全
```

---

## 版本声明 Version

- **目标版本**：kagent **v1.0.0-alpha3**（API v2 已落地）
- 本机旧版 `v0.9.9` 是 legacy API，**勿使用**，详见 [VERSIONS.md](VERSIONS.md)

---

## 三种读者 Three audiences

```
个人开发者 → docs/01-basics          30 分钟
团队       → docs/02-intermediate    1 天
平台工程   → docs/03-idp             按需
```
