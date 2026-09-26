# 多集群管理 Multi-Cluster Management

> 一台开发机连接多个 Kubernetes 集群时，如何安全、精确地管理集群上下文。

---

## 创建 Kind 集群 Kind cluster

本平台用 `make create-kind-cluster` 创建本地 Kind 集群（纯 Docker 方式）。

### 自定义集群名称

```bash
# 默认名称 kagent
make create-kind-cluster

# 自定义名称
make create-kind-cluster KIND_CLUSTER_NAME=my-cluster
```

名称会影响以下内容：

| 字段 | `KIND_CLUSTER_NAME=kagent` | `KIND_CLUSTER_NAME=my-cluster` |
|------|---------------------------|-------------------------------|
| 容器名 | `kagent-control-plane` | `my-cluster-control-plane` |
| kubeconfig 文件 | `~/.kube/kagent.config` | `~/.kube/my-cluster.config` |
| kubeconfig context | `kubernetes-admin@kagent` | `kubernetes-admin@my-cluster` |

### 创建后验证

```bash
# 查看 context
kubectl config current-context

# 查看节点
kubectl get nodes -o wide

# 查询指定集群
kubectl get nodes --context kubernetes-admin@my-cluster
kubectl --kubeconfig ~/.kube/my-cluster.config get pods -n kube-system
```

### 删除集群

```bash
make delete-kind-cluster KIND_CLUSTER_NAME=my-cluster
```

---

## 问题场景 Problem

| 场景 | 风险 |
|------|------|
| 同时管理 dev/staging/prod 集群 | `kubectl delete` 误操作到生产集群 |
| 本地 agent 加载后执行 kubectl | 当前 context 指向未知集群 |
| 多团队共享开发机 | 别人的 context 污染你的操作 |
| 演示机器切换群 | 忘记切回正确集群造成演示事故 |

---

## 规范：Context 命名 Naming convention

推荐格式：`<环境>-<区域>`（也可用 `<团队>-<环境>`）

| 示例 | 说明 |
|------|------|
| `dev-eu` | 开发环境·欧洲区 |
| `staging-apse1` | 预发·亚太 |
| `prod-us` | 生产·美国 |
| `prod-eu` | 生产·欧洲 |
| `team-a-dev` | A 团队开发集群 |

---

## 工作流 Workflow

### 1. 操作前确认

```bash
# 查看当前 context
kubectl config current-context

# 查看所有 context 和基本信息
kubectl config get-contexts

# 输出结构化信息（供 agent 使用）
bash examples/k8s-agent/skills/k8s-cluster-context/scripts/check-context.sh
```

**禁止裸命令**——所有 kubectl 命令必须加 `--context`：

```bash
# ❌ 错误：裸命令，可能打错集群
kubectl get pods

# ✅ 正确：显式指定
kubectl get pods --context prod-eu -n kagent

# ✅ 也正确：临时用环境变量限定
KUBECONFIG=~/.kube/prod-config kubectl get pods
```

### 2. 高危操作确认

删除、变更、写操作前，分两步：

```bash
# 步骤 1：确认 context
kubectl config current-context   # 预期输出：prod-eu

# 步骤 2：确认集群身份
kubectl cluster-info --context prod-eu | head -3
```

### 3. 审计记录

每条 kubectl 写操作建议附带目标信息：

```bash
# 记录操作目标
echo "[$(date)] kubectl apply -f deploy.yaml --context prod-eu" >> ~/.kube/audit.log
```

---

## 配置管理 Config management

### 方案 A：单 kubeconfig 多 context（推荐日常）

```bash
# 查看 context
kubectl config get-contexts

# 临时切换（单命令）
kubectl get nodes --context prod-eu

# 永久切换默认
kubectl config use-context prod-eu
```

### 方案 B：多 kubeconfig 文件（推荐隔离）

```bash
# 用 KUBECONFIG 环境变量隔离
export KUBECONFIG=~/.kube/prod-config
kubectl get pods

# 合并多个配置（冒号分隔）
export KUBECONFIG=~/.kube/dev-config:~/.kube/prod-config

# 用 alias 简化
alias kube-prod='KUBECONFIG=~/.kube/prod-config kubectl'
alias kube-dev='KUBECONFIG=~/.kube/dev-config kubectl'
kube-prod get pods
```

### 方案 C：kubectx 工具

```bash
# 安装 kubectx
kubectx            # 交互式选择 context
kubectx prod-eu    # 切换
kubens team-a      # 切换 namespace
```

---

## Skill 开发规范

所有调用了 `kubectl` 的 skill 必须遵守以下规则：

1. **workflow 开头加 context 确认步骤**
2. **禁止裸 kubectl 命令**——必须用 `--context <cluster>` 显式指定
3. **高危操作前双人确认**——输出 `check-context.sh` 结果再执行

> 参考 `examples/k8s-agent/skills/k8s-cluster-context/` 的实现。

---

## 示例：check-context.sh 输出

```json
{
  "currentContext": "kind-dev",
  "availableContexts": ["kind-dev", "prod-eu", "prod-us", "staging-apse1"],
  "currentCluster": "kind-dev",
  "currentNamespace": "kagent",
  "contextCount": 4,
  "warning": "你有 4 个 context，当前指向 'kind-dev'"
}
```

---

## 边缘情况 Edge cases

| 场景 | 处理 |
|------|------|
| `KUBECONFIG` 环境变量指向非默认路径 | `check-context.sh` 会自动检测 |
| 多文件 `KUBECONFIG`（冒号分隔） | 所有文件会被 kubectl 合并 |
| Helm/Terraform 使用独立 kubeconfig | 需要额外确认，不依赖默认 context |
| `kubectl config use-context` 仅影响当前 shell | 其他终端不受影响 |
| CI/CD 中固定 kubeconfig | 建议在 pipeline 中显式指定，而非依赖默认值 |