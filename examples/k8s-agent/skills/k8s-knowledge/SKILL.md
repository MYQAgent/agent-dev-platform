---
name: k8s-knowledge
description: >
  Kubernetes 核心资源（Pod、Deployment、Service、StatefulSet、CronJob 等）的知识问答与
  清单生成。当用户询问 Kubernetes 概念、需要编写或校验 YAML 清单、或寻求部署最佳实践时使用。
license: Apache-2.0
compatibility: Requires kubectl (optional) and access to a Kubernetes cluster for validation
metadata:
  author: myqagent-dev-platform
  version: "1.0"
  category: kubernetes
allowed-tools: Bash(kubectl:*) Read
---

# Kubernetes 知识库

你是 Kubernetes 核心资源的专家。回答概念问题、生成正确的 YAML 清单、解释最佳实践。

**规则：**
- 生成 YAML 前，核对 apiVersion 与 kind 的对应关系（见下表），绝不臆造 API 版本。
- 字段名不确定时，加载 `references/resource-cheatsheet.md` 核对，不要猜。
- 回答需要细节时，加载对应的 reference 文件，不要凭空发挥。
- 若在 GitOps 仓库中工作，先 `kubectl api-resources --context <cluster>` 盘点可用资源，再写清单。
- **所有 kubectl 命令必须前置 context 校验：运行 `bash <(kubectl config current-context)` 或加载 `k8s-cluster-context` skill 的 `check-context.sh` 确认目标集群。**
- **所有 kubectl 命令必须使用 `--context <cluster>` 显式指定目标集群，禁止使用裸命令。**

## 核心资源速查 Core resources

| Kind | apiVersion | 用途 |
|------|-----------|------|
| Pod | v1 | 最小调度单元 |
| Deployment | apps/v1 | 无状态应用，滚动更新 |
| StatefulSet | apps/v1 | 有状态应用，稳定身份 |
| DaemonSet | apps/v1 | 每个节点一个实例 |
| Job / CronJob | batch/v1 | 一次性 / 定时任务 |
| Service | v1 | 服务发现与负载均衡 |
| Ingress | networking.k8s.io/v1 | HTTP 路由 |
| ConfigMap / Secret | v1 | 配置与敏感数据 |
| PersistentVolumeClaim | v1 | 存储申请 |

## 决策树 Decision tree

- **无状态 Web 应用** → Deployment + Service
- **有状态（数据库/队列）** → StatefulSet + headless Service
- **每个节点都跑（日志/监控）** → DaemonSet
- **定时任务** → CronJob
- **一次性任务** → Job

## 常见清单模式 Common patterns

### Deployment + Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

### ConfigMap 挂载

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.yaml: |
    key: value
```

## 边缘情况 Edge cases

- 需要进一步校验字段时，加载 `references/resource-cheatsheet.md`。
- 若目标集群无某 API 版本，说明该版本可能已废弃，提示用户升级。
