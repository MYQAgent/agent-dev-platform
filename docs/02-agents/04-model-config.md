# ModelConfig LLM 配置

> ModelConfig tells the agent which LLM to use and how to authenticate.

---

## 一句话理解

**ModelConfig 是 LLM 配置**——告诉 agent 用哪个模型、哪个 provider、API key 从哪里拿。

三者的关系：

```
AgentTemplate → modelConfig.name → ModelConfig → 实际 LLM 调用
                      │
                      ▼
               Secret（存 API key）
```

---

## 创建流程 Creation flow

```bash
# 1. 先创建 Secret 保存 API key
kubectl create secret generic deepseek-creds \
  --namespace kagent \
  --from-literal=apiKey=sk-your-deepseek-api-key

# 2. 再创建 ModelConfig 引用该 Secret
kubectl apply -f - <<EOF
apiVersion: kagent.dev/v1alpha3
kind: ModelConfig
metadata:
  name: my-model-config
  namespace: kagent
spec:
  provider: OpenAI
  model: deepseek-chat
  openAI:
    baseUrl: https://api.deepseek.com/v1
  apiKeySecret: deepseek-creds
  apiKeySecretKey: apiKey
EOF
```

---

## 快速选择 Quick selection

| 你的场景 | provider | model | 国内可用 |
|---------|----------|-------|---------|
| 国内直连 / 低成本 | `OpenAI` | `deepseek-chat` | ✅ 直连 |
| 国外 / OpenAI | `OpenAI` | `gpt-4o` | 需代理 |
| 本地 / 完全离线 | `Ollama` | `qwen2.5:7b` | ✅ 完全本地 |
| Anthropic Claude | `Anthropic` | `claude-sonnet-4-20250514` | 需代理 |
| Google Gemini | `Gemini` | `gemini-2.5-flash` | ✅ 可直连 |

---

## 支持的 Provider Supported providers

| provider | 说明 | 专用配置字段 |
|----------|------|-------------|
| `OpenAI` | OpenAI / 兼容 OpenAI API 的第三方 | `openAI.baseUrl`, `temperature` |
| `Anthropic` | Anthropic Claude | `anthropic.baseUrl` |
| `AzureOpenAI` | Azure OpenAI Service | `azureOpenAI.baseUrl` |
| `Ollama` | 本地部署 Ollama | `ollama.host` |
| `Gemini` | Google Gemini（API key） | — |
| `GeminiVertexAI` | Google Vertex AI | — |
| `Bedrock` | AWS Bedrock | — |
| `Mistral` | Mistral AI | — |

> 完整列表见 [ModelConfig 参考](../04-best-practices/modelconfig-reference.md)。

---

## 完整 YAML 示例 Full examples

### DeepSeek（国内推荐）

```yaml
apiVersion: kagent.dev/v1alpha3
kind: ModelConfig
metadata:
  name: deepseek-model-config
  namespace: kagent
spec:
  provider: OpenAI
  model: deepseek-chat
  openAI:
    baseUrl: https://api.deepseek.com/v1
  apiKeySecret: deepseek-creds
  apiKeySecretKey: apiKey
```

### Ollama（本地离线）

```yaml
apiVersion: kagent.dev/v1alpha3
kind: ModelConfig
metadata:
  name: ollama-model-config
  namespace: kagent
spec:
  provider: Ollama
  model: qwen2.5:7b
  ollama:
    host: http://ollama.kagent.svc:11434
  apiKeyPassthrough: false
```

### OpenAI

```yaml
apiVersion: kagent.dev/v1alpha3
kind: ModelConfig
metadata:
  name: openai-model-config
  namespace: kagent
spec:
  provider: OpenAI
  model: gpt-4o
  apiKeySecret: openai-creds
  apiKeySecretKey: apiKey
```

---

## 关键字段 Core fields

| 字段 | 必填 | 说明 |
|------|------|------|
| `spec.provider` | ✅ | 模型 provider（见上表） |
| `spec.model` | ✅ | 模型名称，如 `deepseek-chat`, `gpt-4o` |
| `spec.apiKeySecret` | △ | 存 API key 的 Secret 名称（与 `apiKeyPassthrough` 二选一） |
| `spec.apiKeySecretKey` | △ | Secret 中的 key 名，默认 `apiKey` |
| `spec.apiKeyPassthrough` | △ | 透传入站 A2A 请求的 Bearer token 作为 API key |
| `spec.<provider>.*` | ❌ | provider 专用配置（如 `openAI.baseUrl`） |

> **Ollama 不需要 API key**：设 `apiKeyPassthrough: false`，留空 `apiKeySecret`。

---

## 关键提醒 Reminders

- **先创 Secret，再创 ModelConfig**：Secret 必须先存在，否则 ModelConfig 引用会失败。
- **国内首选 DeepSeek**：OpenAI 兼容协议，`provider: OpenAI` + `baseUrl: https://api.deepseek.com/v1`，无需代理。
- **Digest 不是必需的**：ModelConfig 不像 Harness/AgentTemplate 那样要求 digest 引用，用 name 引用即可。

---

## 下一步 Next

- 创建第一个 agent → [01-first-agent.md](01-first-agent.md)
- Harness 运行时选择 → [02-harness.md](02-harness.md)
- AgentTemplate 行为定义 → [03-agent-template.md](03-agent-template.md)
- ModelConfig 完整参考 → [../04-best-practices/modelconfig-reference.md](../04-best-practices/modelconfig-reference.md)