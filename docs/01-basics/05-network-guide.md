# 国内网络环境配置指南

> 解决 ghcr.io / registry.k8s.io 等源在国内访问慢或不可达的问题。

> **统一镜像源策略**：本指南所有文档的示例代码统一使用 `localhost:5000` 作为演示 registry。  
> `make create-kind-cluster` 会自动内置 registry，`localhost:5000` = 集群内 `k3d-kagent-registry:5000`。  
> 官方镜像（golang-adk 等）来自 ghcr.io/kagent-dev/，需要通过下方方案加速拉取。  
> 生产环境请将 `localhost:5000` 替换为你的实际 registry 地址。

---

## 问题：哪些源被墙/慢？

| 源 | 问题 | 影响组件 |
|----|------|---------|
| `ghcr.io` | 极慢，部分不可达 | 所有 kagent / Substrate 镜像 |
| `registry.k8s.io` | 不可达 | gVisor pause 镜像 |
| `gs://gvisor/releases/` | 不可达 | gVisor 沙箱二进制 |
| `github.com` | 下载慢 | CLI、kubectl-ate |

---

## 方案 A：一键脚本（推荐）

`tools/mirror.sh` 自动完成所有配置：

```bash
# 1. 确保代理已开启（如果宿主机有代理）
export HTTP_PROXY=http://127.0.0.1:7892
export HTTPS_PROXY=http://127.0.0.1:7892

# 2. 运行镜像加速脚本
bash tools/mirror.sh

# 3. 正常安装
make helm-install
```

脚本完成以下操作：

| 步骤 | 说明 |
|------|------|
| 配置 containerd 镜像加速 | docker.io → docker.1ms.run, ghcr.io → ghcr.nju.edu.cn |
| 拉取所有 ghcr.io 镜像 | 通过代理拉取并缓存到本地 registry |
| 拉取 pause 镜像 | registry.k8s.io → docker.1ms.run |
| 重启 k3s | 使镜像加速配置生效 |
| 配置 atelet 代理 | gVisor 沙箱下载依赖代理 |

---

## 方案 B：手动配置镜像加速

### 1. containerd 镜像加速

配置 `/etc/rancher/k3s/registries.yaml`：

```yaml
mirrors:
  docker.io:
    endpoint:
      - "https://docker.1ms.run"
  ghcr.io:
    endpoint:
      - "https://ghcr.nju.edu.cn"
  registry.k8s.io:
    endpoint:
      - "https://docker.1ms.run"
```

然后重启 k3s 生效：

```bash
# k3d 重启
docker exec k3d-kagent-server-0 sh -c 'kill -HUP 1'
# 或 k3d 容器重启
docker restart k3d-kagent-server-0
```

### 2. Docker daemon 代理

```bash
# /etc/systemd/system/docker.service.d/proxy.conf
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7892"
Environment="HTTPS_PROXY=http://127.0.0.1:7892"
Environment="NO_PROXY=localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12"

systemctl daemon-reload && systemctl restart docker
```

### 3. atelet 代理（关键）

atelet 是 Substrate 的节点代理，负责下载 gVisor 沙箱和 pause 镜像。

```bash
kubectl patch daemonset -n ate-system atelet --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"HTTP_PROXY","value":"http://172.29.0.1:7892"}},
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"HTTPS_PROXY","value":"http://172.29.0.1:7892"}},
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"NO_PROXY","value":"localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local,ate-system.svc"}}
]'

kubectl delete pod -n ate-system -l app=atelet --force --grace-period=0
```

---

## 方案 C：本地 registry 全量缓存

`make create-kind-cluster` 已内置 registry（`localhost:5000` → `k3d-kagent-registry:5000`），以下步骤仅在需要手动缓存时使用：

```bash
# 1. 启动本地 registry
docker run -d --restart=always -p 5000:5000 --name gw-registry registry:2

# 2. 拉取并推送所有镜像
for img in \
  ghcr.io/kagent-dev/kagent/controller:1.0.0-alpha3 \
  ghcr.io/kagent-dev/kagent/ui:1.0.0-alpha3 \
  ghcr.io/kagent-dev/kagent/tools:0.2.1 \
  ghcr.io/kagent-dev/kagent/golang-adk@sha256:699c7a36... \
  ghcr.io/kagent-dev/substrate/ateom-gvisor:v0.2.0-beta5 \
  ghcr.io/kagent-dev/substrate/ateapi:v0.2.0-beta5 \
  ghcr.io/kagent-dev/substrate/atecontroller:v0.2.0-beta5 \
  ghcr.io/kagent-dev/substrate/atelet:v0.2.0-beta5 \
  ghcr.io/kagent-dev/substrate/atenet:v0.2.0-beta5 \
  ghcr.io/kagent-dev/substrate/kubernetes-secrets:v0.2.0-beta5 \
  ghcr.io/kagent-dev/substrate/podcertcontroller:v0.2.0-beta5 \
  ghcr.io/kagent-dev/kmcp/controller:0.3.0 \
  registry.k8s.io/pause:3.10.2; do
  docker pull "$img"
  short="${img#ghcr.io/}"
  short="${short#registry.k8s.io/}"
  docker tag "$img" "localhost:5000/mirror/${short}"
  docker push "localhost:5000/mirror/${short}"
done

# 3. containerd 配置指向本地 registry
# 在 registries.yaml 中把 ghcr.io / registry.k8s.io 指向 localhost:5000
```

---

## 问题排查

| 现象 | 原因 | 解决 |
|------|------|------|
| WorkerPool 卡 ContainerCreating | 镜像拉取失败 | 配置 registry 镜像加速 |
| Golden snapshot 卡住 | atelet 无法下载 gVisor/pause | 配置 atelet 代理 |
| Overlay filesystem 错误 | Docker 内嵌套 overlay | `mount -t tmpfs tmpfs /var/lib/ateom-gvisor/actors` |
| `dial tcp 173.194.43.82:443 i/o timeout` | registry.k8s.io 不可达 | 配置镜像加速或代理 |

---

## 已知国内可用镜像源

| 原始源 | 国内镜像 | 说明 |
|-------|---------|------|
| `docker.io` | `docker.1ms.run` | 稳定，推荐 |
| `ghcr.io` | `ghcr.nju.edu.cn` | 南京大学镜像，已验证 |
| `registry.k8s.io` | `docker.1ms.run` | 共用 Docker Hub 镜像站 |
| `quay.io` | `quay.m.daocloud.io` | DaoCloud 镜像 |