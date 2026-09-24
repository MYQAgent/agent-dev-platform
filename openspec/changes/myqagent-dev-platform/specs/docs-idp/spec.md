## ADDED Requirements

### Requirement: 集群搭建说明（controller + Substrate）
系统 SHALL 说明部署 kagent controller 与 Substrate（含 kubectl-ate 铸造 CA/JWT pool）的步骤，并解读 setup-cluster.sh 的关键步骤。

#### Scenario: 搭建平台集群
- **WHEN** 平台工程师按文档执行集群搭建
- **THEN** 得到可运行 agent 的完整集群（controller + Substrate + PostgreSQL）

### Requirement: CI/CD 流水线说明
系统 SHALL 说明 skill 构建 → OCI 发布 → AgentTemplate apply 的自动化流水线。

#### Scenario: 自动化发布
- **WHEN** 团队推送 skill 变更
- **THEN** 流水线自动完成 lint → 打包 → OCI 发布，产出可引用的 digest

### Requirement: 治理说明
系统 SHALL 说明多团队下的治理策略（RBAC、安全策略、observability）。

#### Scenario: 多团队治理
- **WHEN** 多个团队共享平台
- **THEN** 各团队能在 RBAC 约束内自助创建 agent，且有可观测性与安全护栏

### Requirement: 多团队工作流说明
系统 SHALL 说明多团队共享平台的典型工作流。

#### Scenario: 团队自助开发
- **WHEN** 团队按文档初始化 agent 项目并发布
- **THEN** 无需平台团队介入即可完成开发与部署
