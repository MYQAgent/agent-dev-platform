#!/bin/bash
# ============================
# myqagent 国内镜像加速脚本
# 配置 containerd 镜像加速 + 推送到国内 registry
# ============================
set -euo pipefail

# ── 国内镜像地址配置 ──
DOCKER_MIRROR="https://docker.1ms.run"
GHCR_MIRROR="https://ghcr.nju.edu.cn"
K8S_MIRROR="https://docker.1ms.run"

# 需要拉取并推送的镜像列表（ghcr.io 直连慢的）
IMAGES_GHCR=(
  "ghcr.io/kagent-dev/kagent/controller:1.0.0-alpha3"
  "ghcr.io/kagent-dev/kagent/ui:1.0.0-alpha3"
  "ghcr.io/kagent-dev/kagent/tools:0.2.1"
  "ghcr.io/kagent-dev/kagent/golang-adk@sha256:699c7a36daa0050d5954f42ad3b614690d825664cf64ffe8871dbe20dc68464e"
  "ghcr.io/kagent-dev/substrate/ateom-gvisor:v0.2.0-beta5"
  "ghcr.io/kagent-dev/substrate/ateapi:v0.2.0-beta5"
  "ghcr.io/kagent-dev/substrate/atecontroller:v0.2.0-beta5"
  "ghcr.io/kagent-dev/substrate/atelet:v0.2.0-beta5"
  "ghcr.io/kagent-dev/substrate/atenet:v0.2.0-beta5"
  "ghcr.io/kagent-dev/substrate/kubernetes-secrets:v0.2.0-beta5"
  "ghcr.io/kagent-dev/substrate/podcertcontroller:v0.2.0-beta5"
  "ghcr.io/kagent-dev/kmcp/controller:0.3.0"
  "ghcr.io/agentgateway/agentgateway:v0.0.0-alpha.8dba3989@sha256:fdde26d4b0ea11d3e740dc19905dfe9b26e88f40fa8b9985f94ed1d8420e389e"
)

IMAGES_K8S=(
  "registry.k8s.io/pause:3.10.2"
)

# ── 颜色 ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# ── 检测 k3d 集群 ──
check_k3d() {
  if ! command -v k3d &>/dev/null; then
    error "k3d 未安装"; exit 1
  fi
  if ! docker ps --format '{{.Names}}' | grep -q k3d-kagent-server-0; then
    error "k3d 集群 kagent 未运行，请先执行 make create-kind-cluster"
    exit 1
  fi
  info "k3d 集群运行中"
}

# ── 1. 配置 containerd registries.yaml ──
setup_registries() {
  echo ""
  echo "━━━━━ 配置 containerd 镜像加速 ━━━━━"
  echo ""
  docker exec k3d-kagent-server-0 sh -c \
    "printf 'mirrors:\n  docker.io:\n    endpoint:\n      - \"${DOCKER_MIRROR}\"\n  ghcr.io:\n    endpoint:\n      - \"${GHCR_MIRROR}\"\n  registry.k8s.io:\n    endpoint:\n      - \"${K8S_MIRROR}\"\n' > /etc/rancher/k3s/registries.yaml"
  info "registries.yaml 已写入"
  docker exec k3d-kagent-server-0 sh -c 'cat /etc/rancher/k3s/registries.yaml'
}

# ── 2. 启用代理拉取（可选）──
setup_proxy() {
  if [ -n "${HTTP_PROXY:-}" ] || [ -n "${http_proxy:-}" ]; then
    PROXY="${HTTP_PROXY:-${http_proxy}}"
    echo ""
    echo "━━━━━ 配置代理 ── ${PROXY} ━━━━━"
    echo ""
    # 写入 k3s 服务代理配置
    docker exec k3d-kagent-server-0 sh -c 'mkdir -p /etc/systemd/system/k3s.service.d'
    docker exec k3d-kagent-server-0 sh -c \
      "cat > /etc/systemd/system/k3s.service.d/proxy.conf << EOF
[Service]
Environment=\"HTTP_PROXY=${PROXY}\"
Environment=\"HTTPS_PROXY=${PROXY}\"
Environment=\"NO_PROXY=localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local\"
EOF"
    info "k3s 代理配置已写入"
  fi
}

# ── 3. 拉取 + 推送镜像到本地 registry ──
mirror_images() {
  echo ""
  echo "━━━━━ 拉取并推送镜像 ━━━━━"
  echo ""

  GW_REGISTRY="172.29.0.1:5000"
  local_pull=0

  for img in "${IMAGES_GHCR[@]}"; do
    echo ""
    echo "--- $img ---"
    local_name="${GW_REGISTRY}/mirror/$(echo $img | sed 's|ghcr.io/||;s|@sha256.*||;s|:.*||')"
    local_tag="${GW_REGISTRY}/mirror/$(echo $img | sed 's|ghcr.io/||;s|@sha256:|:digest-|')"

    if docker image inspect "$img" &>/dev/null; then
      info "本地已存在"
    else
      echo -n "拉取中... "
      if docker pull "$img" &>/dev/null; then
        info "拉取成功"
      else
        warn "拉取失败，跳过"
        continue
      fi
    fi

    # 推送到本地 registry
    short="${img#ghcr.io/}"
    docker tag "$img" "${GW_REGISTRY}/mirror/${short}" 2>/dev/null
    echo -n "推送中... "
    if docker push "${GW_REGISTRY}/mirror/${short}" &>/dev/null; then
      info "推送成功 → ${GW_REGISTRY}/mirror/${short}"
      ((local_pull++))
    else
      warn "推送失败"
    fi
  done

  # registry.k8s.io 镜像
  for img in "${IMAGES_K8S[@]}"; do
    echo ""
    echo "--- $img ---"
    if docker image inspect "$img" &>/dev/null; then
      info "本地已存在"
    else
      echo -n "拉取中... "
      if docker pull "$img" &>/dev/null; then
        info "拉取成功"
      else
        warn "拉取失败，跳过"
        continue
      fi
    fi
    short="${img#registry.k8s.io/}"
    docker tag "$img" "${GW_REGISTRY}/mirror/registry.k8s.io/${short}" 2>/dev/null
    echo -n "推送中... "
    if docker push "${GW_REGISTRY}/mirror/registry.k8s.io/${short}" &>/dev/null; then
      info "推送成功 → ${GW_REGISTRY}/mirror/registry.k8s.io/${short}"
      ((local_pull++))
    fi
  done

  echo ""
  info "共推送 ${local_pull} 个镜像到本地 registry"
}

# ── 4. 重启 k3s ──
restart_k3s() {
  echo ""
  echo "━━━━━ 重启 k3s ━━━━━"
  echo ""
  docker exec k3d-kagent-server-0 sh -c 'kill -HUP 1' 2>/dev/null || docker restart k3d-kagent-server-0
  echo -n "等待集群就绪"
  for i in $(seq 1 30); do
    kubectl taint nodes k3d-kagent-server-0 node.kubernetes.io/unschedulable- 2>/dev/null || true
    kubectl uncordon k3d-kagent-server-0 2>/dev/null || true
    if kubectl get nodes 2>/dev/null | grep -q Ready; then
      echo ""; info "集群已就绪"; return 0
    fi
    echo -n "."
    sleep 3
  done
  echo ""; error "集群未能就绪"; exit 1
}

# ── 5. atelet 代理配置 ──
setup_atelet_proxy() {
  if [ -n "${HTTP_PROXY:-}" ] || [ -n "${http_proxy:-}" ]; then
    PROXY="${HTTP_PROXY:-${http_proxy}}"
    echo ""
    echo "━━━━━ 配置 atelet 代理 ── ${PROXY} ━━━━━"
    echo ""
    if kubectl get daemonset -n ate-system atelet &>/dev/null; then
      kubectl patch daemonset -n ate-system atelet --type='json' -p="[
        {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/env/-\",\"value\":{\"name\":\"HTTP_PROXY\",\"value\":\"$PROXY\"}},
        {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/env/-\",\"value\":{\"name\":\"HTTPS_PROXY\",\"value\":\"$PROXY\"}},
        {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/env/-\",\"value\":{\"name\":\"NO_PROXY\",\"value\":\"localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local,ate-system.svc\"}}
      ]" 2>/dev/null
      kubectl delete pod -n ate-system -l app=atelet --force --grace-period=0 2>/dev/null || true
      info "atelet 代理已配置"
    fi
  fi
}

# ── 主流程 ──
main() {
  check_k3d
  setup_registries
  setup_proxy
  mirror_images
  restart_k3s
  setup_atelet_proxy
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${GREEN}  国内镜像加速配置完成${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "后续 Helm 安装时自动走国内镜像源，无需额外配置。"
  echo "执行: make helm-install"
}

main "$@"