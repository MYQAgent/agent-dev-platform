## ADDED Requirements

### Requirement: skill 设计最佳实践
系统 SHALL 提供 skill 设计原则（职责单一、workflow 显式、reference 按需加载、边缘情况处理）。

#### Scenario: 设计评审
- **WHEN** 读者设计新 skill 时参照最佳实践
- **THEN** 产出的 skill 符合 Agent Plugins 规范且可维护

### Requirement: 安全最佳实践
系统 SHALL 提供安全清单（secret 处理、MCP 工具授权、RBAC、只读模式）。

#### Scenario: 安全检查
- **WHEN** 读者发布 skill 前对照安全清单
- **THEN** 能识别并规避 secret 泄露与越权工具调用风险

### Requirement: v0.x legacy 迁移说明
系统 SHALL 说明从 kagent v0.x（SandboxAgent）迁移到 v2（Harness/AgentTemplate/AgentInstance）的要点。

#### Scenario: 迁移遗留 agent
- **WHEN** 用户持有 v0.x 的 SandboxAgent 配置
- **THEN** 文档说明 legacy API 无自动迁移，需重建为 Harness/AgentTemplate 并指向相应概念映射
