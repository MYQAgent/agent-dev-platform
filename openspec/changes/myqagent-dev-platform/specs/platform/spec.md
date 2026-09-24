## ADDED Requirements

### Requirement: IDP 平台层
系统 SHALL 提供平台层结构（helm 引用上游 chart、terraform 集群初始化、多团队示例）。

#### Scenario: 平台部署
- **WHEN** 平台工程师使用 platform/ 下的 helm/terraform 配置
- **THEN** 能部署 kagent controller 与 kmcp controller，并支持多团队示例
