## ADDED Requirements

### Requirement: 专业级 k8s-agent 示例
系统 SHALL 提供一个专业级 k8s-agent 示例，包含 3 个 skill（k8s-knowledge / k8s-troubleshoot / k8s-security），每个 skill 含 SKILL.md 及所需 scripts/references/evals。

#### Scenario: 完整 skill 组件
- **WHEN** 读者查看 k8s-agent 的 skills 目录
- **THEN** 能看到 SKILL.md、scripts、references、evals 等生产级组件的完整示例

### Requirement: 全链路打包与引用
系统 SHALL 提供 k8s-agent 的 plugin.json、多平台 plugin 清单（.claude-plugin + .codex-plugin）、以及打包为 OCI 并供 AgentTemplate 引用的完整链路。

#### Scenario: 打通发布链路
- **WHEN** 读者按 Makefile 执行 validate → build → OCI push
- **THEN** 得到可被 AgentTemplate 通过 OCI digest 引用的 skill 产物

### Requirement: MCP 工具集成示例
系统 SHALL 提供 k8s-agent 的 remotemcpserver.yaml 与 ToolBinding 示例，展示接入 Kubernetes MCP 工具。

#### Scenario: 接入集群工具
- **WHEN** 读者应用 remotemcpserver 并在 AgentTemplate 声明 ToolBinding
- **THEN** k8s-agent 能通过 MCP 调用 Kubernetes 工具
