# ModelConfig 参考

> ModelConfig CRD 字段说明与 provider 配置指南。

---

## 核心字段 Core fields

```yaml
apiVersion: kagent.dev/v1alpha3
kind: ModelConfig
metadata:
  name: my-config
  namespace: kagent
spec:
  # 模型名称（必填）
  model: gpt-4o

  # API Key 所在 Secret 名称（二选一：apiKeySecret 或 apiKeyPassthrough）
  apiKeySecret: my-credentials

  # Secret 中的 key 名
  apiKeySecretKey: apiKey

  # 从入站 A2A 请求透传 Bearer token 作为 API key（与 apiKeySecret 互斥）
  apiKeyPassthrough: false

  # 模型 provider（必填）
  provider: OpenAI            # 见下方「支持的 provider」列表

  # ── provider 专用配置（按需） ──
  openAI:                     # provider=OpenAI 时可用
    baseUrl: https://api.deepseek.com/v1   # 自定义 endpoint
    temperature: "0.7"
    maxTokens: 4096
    maxCompletionTokens: 8192

  anthropic:                  # provider=Anthropic 时可用
    baseUrl: https://api.anthropic.com

  ollama:                     # provider=Ollama 时可用
    host: http://ollama:11434
```

---

## 支持的 Provider Supported providers

| provider 值 | 说明 | 国内可用性 |
|-------------|------|-----------|
| `OpenAI` | OpenAI / 兼容 OpenAI API 的第三方（如 DeepSeek、通义千问） | DeepSeek 可直连 ✅ |
| `Anthropic` | Anthropic Claude | 需代理 |
| `AzureOpenAI` | Azure OpenAI Service | 国内 Azure 可用 ✅ |
| `Ollama` | 本地部署 Ollama | 完全本地 ✅ |
| `Gemini` | Google Gemini（API key 方式） | 可直连 ✅ |
| `GeminiVertexAI` | Google Vertex AI | 需要代理 |
| `AnthropicVertexAI` | Anthropic via Vertex AI | 需要代理 |
| `Bedrock` | AWS Bedrock | 国内区域可用 ✅ |
| `SAPAICore` | SAP AI Core | 视部署区域 |
| `Foundry` | Azure AI Foundry | 国内 Azure 可用 ✅ |
| `Mistral` | Mistral AI | 需代理 |

---

## 国内推荐配置 Recommended for China

### DeepSeek（Appendice IA 兼容 OpenAI API）

```yaml
apiVersion: kagent.dev/v1alpha3
kind: ModelConfig
metadata:
  name: deepseek-model-config
  namespace: kagent
spec:
  provider: OpenAI
  model: deepseek-chat        # 或 deepseek-reasoner
  openAI:
    baseUrl: https://api.deepseek.com/v1
  apiKeySecret: deepseek-credentials
  apiKeySecretKey: apiKey
```

创建 Secret：

```bash
kubectl create secret generic deepseek-credentials \
  --namespace kagent \
  --from-literal=apiKey=sk-your-deepseek-api-key
```

### Ollama（本地部署，完全离线）

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

> Ollama 无需 API key，apiKeySecret 留空即可。

---

## Secret 规范 Secret conventions

| provider | Secret 内容 | 示例命令 |
|----------|-------------|----------|
| `OpenAI` | 任意 key，由 `apiKeySecretKey` 指定 | `kubectl create secret generic my-creds --from-literal=apiKey=sk-...` |
| `SAPAICore` | 固定 key: `client_id` + `client_secret` | `kubectl create secret generic sap-creds --from-literal=client_id=... --from-literal=client_secret=...` |
| 其余 provider | 任意 key（参考 OpenAI） | — |

---

## TLS 配置 TLS config

连接私有 LLM 网关（如 LiteLLM）时的证书配置：

```yaml
spec:
  tls:
    disableVerify: false       # 关闭证书验证（仅开发）
    caCertSecretRef: my-ca    # 自定义 CA 证书 Secret
    caCertSecretKey: ca.crt
    disableSystemCAs: false   # 禁用系统 CA
```

---

## 完整示例 Full examples

参见：
- `examples/k8s-agent/modelconfig.yaml`
- `template/agent/modelconfig.yaml`