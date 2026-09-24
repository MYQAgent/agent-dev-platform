## ADDED Requirements

### Requirement: skill-bundle 脚手架
系统 SHALL 提供可复制的 skill 库脚手架（skills 目录 + plugin.json + Makefile），用于打包发布为 OCI。

#### Scenario: 复制即用
- **WHEN** 开发者复制 skill-bundle 模板并填入自己的 skill
- **THEN** 得到可执行 validate/build/publish 的标准 skill 库项目

### Requirement: agent 项目脚手架
系统 SHALL 提供可复制的 agent 项目脚手架（agenttemplate.yaml + harness.yaml + modelconfig.yaml + remotemcpserver.yaml），用于部署到 K8s。

#### Scenario: 复制即用
- **WHEN** 开发者复制 agent 模板并填入自己的配置
- **THEN** 得到可 apply 到集群的完整 agent 项目
