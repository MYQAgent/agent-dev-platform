## ADDED Requirements

### Requirement: Agent Plugins 1.0.0 格式说明
系统 SHALL 说明 Agent Plugins 1.0.0 的 skill 格式（SKILL.md frontmatter + plugin.json），并以 fluxcd/agent-skills 作为写法对照。

#### Scenario: 理解格式
- **WHEN** 读者阅读 skill-format 文档
- **THEN** 能写出符合规范的 SKILL.md（name/description/frontmatter）并理解 plugin.json 根清单作用

### Requirement: skill 打包为 OCI 并引用
系统 SHALL 说明将 skill 打包为 OCI 产物并被 AgentTemplate 的 `spec.skills[].source.oci` 引用的完整流程。

#### Scenario: 打包与引用
- **WHEN** 读者按文档执行打包与引用步骤
- **THEN** 生成的 AgentTemplate 通过 OCI digest 引用 skill，且能区分「格式标准」与「分发模型」

### Requirement: MCP 集成说明
系统 SHALL 说明通过 RemoteMCPServer CRD 与 ToolBinding 为 agent 接入 MCP 工具。

#### Scenario: 接入 MCP 工具
- **WHEN** 读者定义 RemoteMCPServer 并在 AgentTemplate 中声明 ToolBinding
- **THEN** agent 能通过 A2A 调用该 MCP server 提供的工具

### Requirement: Harness 四种 adapter 说明
系统 SHALL 说明 Harness 的四种运行时适配器（kagent / Codex / Claude / BYO）及其选择依据。

#### Scenario: 选择适配器
- **WHEN** 读者需要为 agent 选择运行时
- **THEN** 能根据场景（原生/Codex/Claude/自定义镜像）选择正确的 Harness 变体

### Requirement: evals 与测试说明
系统 SHALL 说明如何为 skill 编写 evals/evals.json 并运行评估。

#### Scenario: 编写并运行 evals
- **WHEN** 读者为 skill 编写 evals 场景并执行测试
- **THEN** 得到每个期望的通过/失败评分
