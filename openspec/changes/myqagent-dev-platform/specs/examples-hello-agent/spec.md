## ADDED Requirements

### Requirement: 最小可运行 AgentTemplate 示例
系统 SHALL 提供一个最小 hello-agent 示例，仅含 AgentTemplate（内嵌 systemPrompt），可被 Harness 接纳后跑通。

#### Scenario: 最小跑通
- **WHEN** 读者应用 hello-agent 的 AgentTemplate（并配置对应 Harness）
- **THEN** agent 进入 Ready 状态并可对话
