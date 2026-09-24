## ADDED Requirements

### Requirement: 零集群编写 skill 教程
系统 SHALL 提供一篇无需 Kubernetes 集群即可完成的「编写 SKILL.md」教程，作为第一课。

#### Scenario: 新手零依赖入门
- **WHEN** 读者仅有文本编辑器与本地校验工具（skills-ref 或 skilltoolset）
- **THEN** 教程引导读者完成一个符合 Agent Plugins 1.0.0 的 SKILL.md 并通过本地校验

### Requirement: kagent CLI 与 kmcp 安装说明
系统 SHALL 说明安装 kagent v1.0.0-alpha3 CLI 与 kmcp 的步骤，并标注本机旧版（v0.9.9）需升级。

#### Scenario: 安装指定版本
- **WHEN** 读者按文档执行安装命令
- **THEN** 得到 kagent v1.0.0-alpha3 与 kmcp 的可执行二进制，且版本校验通过

### Requirement: v2 架构一页说明
系统 SHALL 用一页图示说明 Harness / AgentTemplate / AgentInstance / ModelConfig / RemoteMCPServer 的关系。

#### Scenario: 理解架构
- **WHEN** 读者阅读架构页
- **THEN** 能区分「K8s CRD」与「gRPC 资源（AgentInstance）」，并理解 Substrate 是唯一运行时

### Requirement: 官方镜像一条命令跑通 agent
系统 SHALL 提供消费者视角的「官方镜像 + Helm 一条命令」跑通流程。

#### Scenario: 快速体验
- **WHEN** 读者用官方镜像执行 make create-kind-cluster + helm-install
- **THEN** 无需自行编译即可通过 UI 与 agent 对话

### Requirement: 本地一键预览文档
系统 SHALL 提供 make 命令一键本地预览文档，并默认使用 docsify 渲染（含侧边栏导航与搜索）。

#### Scenario: 启动预览
- **WHEN** 开发者执行 make docs
- **THEN** 本地启动 docsify 预览服务，文档以渲染后的形态展示，带侧边栏导航
