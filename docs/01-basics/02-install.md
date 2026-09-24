# 安装：kagent CLI 与 kmcp

> Install the kagent CLI and kmcp — 成本级别 ②（本地二进制，无需集群）

---

## 核心命令 Core commands

```bash
# kagent CLI（agent 开发）
curl -fsSL -o /usr/local/bin/kagent \
  https://github.com/kagent-dev/kagent/releases/download/v1.0.0-alpha3/kagent-linux-amd64
chmod +x /usr/local/bin/kagent
kagent version    # 期望含 kagent_version: "1.0.0-alpha3"

# kmcp CLI（MCP server 开发）
curl -fsSL https://raw.githubusercontent.com/kagent-dev/kmcp/refs/heads/main/scripts/get-kmcp.sh | bash
kmcp --help
```

> 其他平台（darwin-amd64 / darwin-arm64 / linux-arm64）把 URL 中的 `linux-amd64` 换成对应名称即可。

---

## 为什么需要两个 CLI？Why two CLIs?

```
kagent CLI     → 管 agent（AgentTemplate / Harness / AgentInstance 工作流）
kmcp CLI       → 管 MCP server（脚手架、工具、构建、部署）
```

两者互补：agent 通过 `RemoteMCPServer` 引用 kmcp 构建的 MCP server。

---

## 检查旧版本 Check for legacy version

如果本机已有旧版 `kagent`（`v0.9.9`），它会生成 `SandboxAgent` 这种 legacy 资源，**在 v2 中已废弃**。务必升级：

```bash
kagent version
# 若输出 "0.9.9"，按上面命令覆盖安装 v1.0.0-alpha3
```

详见 [VERSIONS.md](../../VERSIONS.md)。

---

## 其他前置依赖 Other prerequisites

仅当你要**运行** agent（而非只写 skill）时才需要：

| 工具 | 版本 | 用途 |
|------|------|------|
| Kind | v0.27+ | 本地 K8s 集群 |
| kubectl | v1.33+ | 操作集群 |
| Helm | 最新 | 安装 kagent |
| Docker + Buildx | v0.23+ | 构建镜像（贡献者路径） |
| Go | v1.27+ | 构建（贡献者路径） |

**只写 skill 不需要以上任何东西。**

---

## 下一步 Next

- 想理解 v2 架构 → [03-architecture.md](03-architecture.md)
- 想直接跑起来 → [04-run-agent.md](04-run-agent.md)
