# 创建第一个 agent

> Create your first agent — Harness + AgentTemplate + ModelConfig，从零到对话。

所有示例 YAML 见 [examples/](examples/) 目录，可直接 apply：

```bash
kubectl apply -f docs/02-agents/examples/
```

---

## 前置依赖

- Docker（k3d 自动安装）/ kubectl / Helm
- 一个模型 API key（OpenAI / DeepSeek / Ollama 任选）
- `export KUBECONFIG=$HOME/.kube/config`

> **国内网络用户**：ghcr.io / registry.k8s.io 可能访问慢或不可达。  
> 请先执行 `bash tools/mirror.sh` 配置镜像加速，详见 [network-guide.md](../01-basics/05-network-guide.md)。  
> `make create-kind-cluster` 会自动内置本地 registry（`localhost:5000`），所有示例直接使用。

```bash
# 建集群
make create-kind-cluster

# 设 API key（以 OpenAI 为例）
export KAGENT_DEFAULT_MODEL_PROVIDER=OpenAI
export OPENAI_API_KEY=sk-your-openai-api-key

# Helm 安装 kagent（controller + UI + PostgreSQL）
make helm-install

# 打开 UI（可选）
kubectl port-forward -n kagent svc/kagent-ui 8082:8080

# 外部机器访问（加 --address 0.0.0.0）
kubectl port-forward --address 0.0.0.0 -n kagent svc/kagent-ui 8082:8080
```

> 纯 Helm 命令（不依赖 Makefile）：
> ```bash
> helm upgrade --install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds --version 1.0.0-alpha3 --namespace kagent --create-namespace
> helm upgrade --install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent --version 1.0.0-alpha3 --namespace kagent -f your-values.yaml
> ```

---

## Step 1：配置 LLM（ModelConfig）

Agent 需要一个 LLM 后端。先创建保存 API key 的 Secret，再创建 ModelConfig：

```bash
# 创建 Secret（以 DeepSeek 为例）
kubectl create secret generic deepseek-creds \
  --namespace kagent \
  --from-literal=apiKey=sk-your-deepseek-api-key

# 创建 ModelConfig（选一个 provider，取消注释后 apply）
kubectl apply -f examples/modelconfig.yaml
```

> ModelConfig 介绍详见 [04-model-config.md](04-model-config.md)。  
> 示例文件见 [examples/modelconfig.yaml](examples/modelconfig.yaml)（内含 OpenAI / DeepSeek / Ollama 三组配置，用 `---` 分隔）。

---

## Step 2：创建运行时（Harness）

Harness 描述 agent「怎么跑」——用什么运行时镜像、跑在哪个 WorkerPool 上、接纳哪些 AgentTemplate。

```bash
kubectl apply -f examples/harness.yaml
```

完整内容见 [examples/harness.yaml](examples/harness.yaml)。

---

## Step 3：创建 agent（AgentTemplate）

AgentTemplate 描述 agent「跑什么」——system prompt、引用哪个 ModelConfig、有哪些技能。

关键：`metadata.labels` 必须匹配 Harness 的 `allowedAgentTemplates.selector`，否则不会被接纳。

```bash
kubectl apply -f examples/agenttemplate.yaml
```

> AgentTemplate 详细介绍详见 [03-agent-template.md](03-agent-template.md)。  
> 示例文件见 [examples/agenttemplate.yaml](examples/agenttemplate.yaml)。

---

## Step 4：验证编译就绪

检查 AgentTemplate 是否被 Harness 接纳并编译通过：

```bash
kagent get agent-template my-first-agent
```

期望输出：

```
+----------------+------------------+-------+----------------------+
| NAME           | HARNESS          | READY | CREATED              |
+----------------+------------------+-------+----------------------+
| my-first-agent | my-harness       | TRUE  | 2026-08-31T15:01:44Z |
+----------------+------------------+-------+----------------------+
```

`READY` 为 `FALSE` 时查看具体失败阶段：

```bash
kagent get agent-template my-first-agent -o json
```

四个 conditions 的含义：

| Condition | 含义 | 失败常见原因 |
|-----------|------|------------|
| `Accepted` | Harness 的 selector 是否匹配 | label 不匹配 |
| `ResolvedRefs` | ModelConfig / 工具引用是否存在 | ModelConfig 名写错 |
| `Compatible` | 配置是否适合该 Harness 运行时 | 不支持的 provider |
| `Ready` | 编译已完成 | 镜像 digest 无效 |

---

## Step 5：创建 AgentInstance 并对话

AgentInstance 是一个可运行的对话实例。创建它会在 WorkerPool 上启动一个 Actor：

```bash
# 创建实例
kagent create agent-instance \
  --harness my-harness \
  --agent-template my-first-agent
```

保存 ID 并对话：

```bash
export INSTANCE_ID=$(kagent get agent-instance -o json \
  | jq -r '[.agentInstances[] | select(.agentTemplate.name == "my-first-agent")] | sort_by(.createdAt) | last | .id')

kagent invoke --agent-instance $INSTANCE_ID --task "What is 2+2?"
# 输出: 4

kagent invoke --agent-instance $INSTANCE_ID --task "What did I just ask you?"
# 输出: You asked what 2+2 is.
```

对话也通过 UI 可见：`kubectl port-forward -n kagent svc/kagent-ui 8082:8080` → 浏览器访问 `http://localhost:8082`。如需外部 IP 访问，加 `--address 0.0.0.0`。

---

## 清理

```bash
# 删除 AgentInstance
kagent get agent-instance -o json \
  | jq -r '.agentInstances[] | select(.agentTemplate.name == "my-first-agent") | .id' \
  | xargs -n1 kagent delete agent-instance

# 删除 CRD
kubectl delete agenttemplate my-first-agent -n kagent
kubectl delete harness my-harness -n kagent
kubectl delete modelconfig my-model-config -n kagent
```

---

## 下一步

- 理解 Harness 四种 adapter → [02-harness.md](02-harness.md)
- 写自己的 skill 并接入 → [../03-skills/01-skill-format.md](../03-skills/01-skill-format.md)
- 架构全景 → [../01-basics/03-architecture.md](../01-basics/03-architecture.md)