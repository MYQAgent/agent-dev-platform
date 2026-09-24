# 运行你的第一个 agent（消费者路径）

> Run your first agent using official images — 成本级别 ④（官方镜像 + Helm，无需自行编译）

---

## 核心命令 Core commands

```bash
# 1. 建 Kind 集群
make create-kind-cluster

# 2. 设模型 provider 与 key
## 方案 A：OpenAI
export KAGENT_DEFAULT_MODEL_PROVIDER=OpenAI
export OPENAI_API_KEY=sk-your-openai-api-key

## 方案 B：DeepSeek（国内直连）
export KAGENT_DEFAULT_MODEL_PROVIDER=OpenAI
export DEEPSEEK_API_KEY=sk-your-deepseek-api-key
# 注意：需在 ModelConfig 中设置 openAI.baseUrl=https://api.deepseek.com/v1

# 3. Helm 安装（controller + UI + PostgreSQL 自动部署）
make helm-install

# 4. 打开 UI
kubectl port-forward svc/kagent-ui 8001:8080
# 浏览器访问 http://localhost:8001
```

> 这条路径用官方发布镜像，**不需要编译任何代码**，几分钟内可对话。

---

## 两条路径对比 Two paths

```
路径 A：消费者（本页）        路径 B：贡献者
─────────────────────        ─────────────────────
官方镜像 + Helm               本地改代码 + 构建镜像
make helm-install             setup-cluster.sh（10 步）
不碰 Substrate 细节            需 Substrate + kubectl-ate
                                 + CA/JWT pool
适合：体验、学习、运行        适合：改 kagent 源码
```

路径 B 详见 [../03-idp/01-cluster-setup.md](../03-idp/01-cluster-setup.md)。

---

## 前置依赖 Prerequisites

- Kind v0.27+ / kubectl v1.33+ / Helm / Docker
- 一个模型 API key（OpenAI / Anthropic / Gemini / Ollama 任选）

> 注意：`make` 命令来自 kagent 源码仓库的 Makefile。若你不 clone kagent 仓库，也可直接用 Helm 命令等价安装（见下）。

---

## 纯 Helm 安装（不依赖 Makefile）Helm-only install

```bash
# 安装 CRD
helm upgrade --install kagent-crds \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --version 1.0.0-alpha3 --namespace kagent --create-namespace

# 安装 kagent（controller + UI + PostgreSQL）
helm upgrade --install kagent \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --version 1.0.0-alpha3 --namespace kagent -f your-values.yaml
```

---

## 第一个 agent：Harness + AgentTemplate 对

集群起来后，需要一个 Harness 和它接纳的 AgentTemplate：

```yaml
# harness.yaml
apiVersion: kagent.dev/v1alpha3
kind: Harness
metadata:
  name: kagent
  namespace: kagent
spec:
  kagent: {}
  workload:
    image: ghcr.io/kagent-dev/kagent/golang-adk@sha256:<digest>
  substrate:
    workerPoolRef:
      name: kagent-default
    snapshotPolicy:
      location: s3://ate-snapshots/kagent
  allowedAgentTemplates:
    selector:
      matchLabels:
        kagent.dev/harness: kagent
---
# agenttemplate.yaml
apiVersion: kagent.dev/v1alpha3
kind: AgentTemplate
metadata:
  name: assistant
  namespace: kagent
  labels:
    kagent.dev/harness: kagent
spec:
  modelConfig:
    name: default-model-config
  description: A general-purpose assistant.
  systemPrompt: You are a helpful assistant running on kagent.
```

```bash
kubectl apply -f harness.yaml -f agenttemplate.yaml

# 等待 Ready（Substrate 启动 golden actor 并快照，约 1 分钟）
kubectl get agenttemplate -n kagent assistant \
  -o jsonpath='{.status.harnesses[0].conditions[?(@.type=="Ready")].status}'
# 期望输出 True
```

> 一个 template 没有被任何 Harness 接纳时，会被创建但什么都不做——这是最容易困惑的状态。

---

## 下一步 Next

- 理解架构细节 → [03-architecture.md](03-architecture.md)
- 写自己的 skill 并接入 → [../02-intermediate/01-skill-format.md](../02-intermediate/01-skill-format.md)
