---
name: k8s-cluster-context
description: >
  管理多个 Kubernetes 集群 context：确认当前目标集群、检测 context 冲突、
  查看集群信息。当用户需要切换/确认集群、或执行跨集群操作时使用。
license: Apache-2.0
compatibility: Requires kubectl with a valid kubeconfig (~/.kube/config or KUBECONFIG)
metadata:
  author: myqagent-dev-platform
  version: "1.0"
  category: kubernetes
allowed-tools: Bash(kubectl:*) Read
---

# Kubernetes 集群上下文管理

你是 Kubernetes 集群上下文管理专家。负责确保所有 kubectl 操作精确指向目标集群，避免误操作。

**规则：**
- 任何 kubectl 命令前必须先运行 `scripts/check-context.sh` 确认当前 context。
- 所有 kubectl 命令必须使用 `--context <cluster>` 显式指定目标集群，禁止裸命令。
- 高危操作（删除资源、写操作）前必须双人确认集群身份。

## 工作流 Workflow

### 1. Context 确认与冲突检测

```bash
# 查看当前 context 和可用集群列表
bash scripts/check-context.sh

# 手动查看完整 kubeconfig
kubectl config view --minify --output 'jsonpath={.current-context}'
kubectl config get-contexts
```

### 2. 集群信息查看

确认 context 后，精准查看目标集群信息：

```bash
kubectl cluster-info --context <cluster>
kubectl version --context <cluster> --short
kubectl get nodes --context <cluster>
kubectl api-resources --context <cluster> | head -20
kubectl get namespaces --context <cluster>
```

### 3. Context 切换

```bash
# 临时切换（单命令）
kubectl get pods --context prod-eu

# 永久切换
kubectl config use-context prod-eu

# 切换 namespace（不切集群）
kubectl config set-context --current --namespace=team-a
```

## 辅助脚本 Helper scripts

运行 `scripts/check-context.sh` 输出结构化 JSON：

```json
{
  "currentContext": "kind-dev",
  "availableContexts": ["kind-dev", "prod-eu", "prod-us"],
  "currentCluster": "kind-dev",
  "currentNamespace": "kagent",
  "contextCount": 3,
  "warning": "你有 3 个 context，当前指向 'kind-dev'"
}
```

## Context 命名规范 Naming convention

| 格式 | 示例 | 说明 |
|------|------|------|
| `<env>-<region>` | `dev-eu`, `prod-us`, `staging-apse1` | 推荐 |
| `<env>-<cluster>` | `prod-main`, `prod-dr` | 多集群部署 |

## 边缘情况 Edge cases

- `KUBECONFIG` 环境变量可能指向非默认路径，`check-context.sh` 会检测。
- 多文件 `KUBECONFIG`（冒号分隔）会被合并，逐个文件检查。
- `kubectl config use-context` 仅修改当前 kubeconfig，不影响其他进程的 context。
- Helm/Terraform 等工具可能使用独立的 kubeconfig，需额外确认。