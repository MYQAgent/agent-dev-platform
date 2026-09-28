# 工具链安装 Toolchain

> 构建和发布 skill 需要的 CLI 工具。

> **统一镜像源说明**：本指南所有示例使用 `localhost:5000` 作为演示 registry。  
> 你只需 `docker run -d -p 5000:5000 --name registry registry:2` 即可启动本地 registry，跟着示例完整跑通。  
> 生产环境请替换为你的实际 registry 地址（如 ghcr.io、阿里云 ACR、自建 Harbor）。

---

## 自建本地演示 registry

一行命令启动：

```bash
docker run -d --restart=always -p 5000:5000 --name registry registry:2
```

验证：

```bash
curl http://localhost:5000/v2/
# 输出: {}
```

> 所有后续示例的 `localhost:5000` 都指向这个 registry。用完可删：
> `docker rm -f registry`

---

## oras — OCI artifact 工具

### 是什么

**ORAS**（OCI Registry as Storage）是一个 CLI 工具，用于把**任意文件/目录**推送到 OCI Registry，而不是推送容器镜像。

### 与 docker push 的区别

| | docker push | oras push |
|---|---|---|
| 推送内容 | 容器镜像（有 Dockerfile、可运行） | 文件/目录（无 Dockerfile、只存数据） |
| 用途 | 部署运行时 | 发布 skill 内容 |
| 产物 | 可执行容器 | 静态 artifact（SKILL.md + scripts） |
| 在本项目的使用 | BYO 自定义镜像 | Skill OCI 制品 |

### 安装

```bash
# Linux amd64
curl -fsSL https://github.com/oras-project/oras/releases/download/v1.3.4/oras_1.3.4_linux_amd64.tar.gz \
  | tar -xz -C /usr/local/bin oras
chmod +x /usr/local/bin/oras

# macOS
brew install oras

# 验证
oras version
```

> 其他平台和版本见 [oras 官方发布页](https://github.com/oras-project/oras/releases/tag/v1.3.4)。

### 常用命令

```bash
# 推送 skill 目录为 OCI artifact
oras push localhost:5000/my-org/k8s-skills:0.1.0 ./skills

# 拉取 OCI artifact 到本地
oras pull localhost:5000/my-org/k8s-skills@sha256:<digest>

# 查看 artifact 的 digest
oras manifest fetch localhost:5000/my-org/k8s-skills:0.1.0 | jq -r '.digest'
# 输出: sha256:699c7a36daa00...

# 列出仓库中的 tag
oras repo tags localhost:5000/my-org/k8s-skills
```

### 登录 registry

```bash
# 登录本地 registry（无需认证）
# 登录远程 registry（如 ghcr.io）
oras login ghcr.io -u <用户名>
# 输入 Personal Access Token 作为密码
```

---

## skills-ref — SKILL.md 校验工具

### 是什么

`skills-ref` 是一个 npm 包，用于校验 SKILL.md 的 frontmatter 字段和目录结构是否符合 Agent Plugins 1.0.0 规范。

### 安装和使用

```bash
# 无需安装，直接用 npx（Node.js 自带）
npx skills-ref validate ./skills/k8s-knowledge

# 或全局安装
npm install -g @kagent/skills-ref
skills-ref validate ./skills/k8s-knowledge
```

> 需要 Node.js >= 18。如果未安装 Node.js：
> ```bash
> # Linux
> curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
> apt-get install -y nodejs
> 
> # macOS
> brew install node
> ```

---

## jq — JSON 命令行处理器

### 是什么

`jq` 用于从 JSON 输出中提取信息（如 OCI digest）。

### 安装

```bash
# Linux
apt-get install -y jq        # Debian/Ubuntu
yum install -y jq            # CentOS/RHEL

# macOS
brew install jq

# 验证
jq --version
```

### 常用在本项目的命令

```bash
# 从 oras manifest 中提取 digest
oras manifest fetch localhost:5000/my-org/k8s-skills:0.1.0 | jq -r '.digest'

# 验证 Docker 镜像 digest
docker inspect localhost:5000/my-org/custom-agent:0.1.0 | jq -r '.[0].RepoDigests[0]'
```

---

## 工具速查 Tool quick reference

| 工具 | 版本 | 用途 | 安装验证 |
|------|------|------|---------|
| `oras` | >= 1.3.4 | OCI artifact 推送/拉取 | `oras version` |
| `skills-ref` | latest | SKILL.md 校验 | `npx skills-ref --help` |
| `jq` | >= 1.6 | JSON 提取 digest | `jq --version` |

---

## 下一步 Next

- Skill 完整指南 → [01-skill-format.md](01-skill-format.md)
- 打包 OCI 并引用 → [02-skill-bundle.md](02-skill-bundle.md)