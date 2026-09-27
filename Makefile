# myqagent-dev-platform
# 文档查看与常用命令统一入口。Run `make help` for available targets.

.PHONY: help docs docs-http docs-mkdocs docs-vitepress docs-github
.PHONY: create-kind-cluster delete-kind-cluster kind-kubecfg helm-install use-existing-cluster

PORT              ?= 3080
KIND_CLUSTER_NAME ?= kagent
K3D_CLUSTER_NAME  ?= $(KIND_CLUSTER_NAME)
# 0=自动检测空闲端口，可指定如 KIND_API_PORT=8443
KIND_API_PORT     ?= 0
HELM_NAMESPACE    ?= kagent
KAGENT_VERSION    ?= 1.0.0-alpha3

# 自动检测 kubectl 当前读的 kubeconfig 文件
KUBECONFIG_TARGET ?= $(shell \
  if [ -n "$$KUBECONFIG" ]; then echo "$${KUBECONFIG%%:*}"; \
  elif [ -L "$$(command -v kubectl)" ] && \
       [ "$$(readlink -f $$(command -v kubectl))" = "/usr/local/bin/k3s" ]; then \
    echo "/etc/rancher/k3s/k3s.yaml"; \
  else \
    echo "$$(HOME)/.kube/config"; \
  fi)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'

docs: ## docsify 预览文档（浏览器端渲染，静态服务器，绑定 0.0.0.0）
	python3 -m http.server $(PORT) --bind 0.0.0.0 --directory docs

docs-http: docs ## python 静态服务器（别名，同样可渲染 docsify）

docs-mkdocs: ## mkdocs 预览（需 pip install mkdocs）
	mkdocs serve

docs-vitepress: ## vitepress 预览（需 npm install）
	npx vitepress dev docs

docs-github: ## 提示：推送到 GitHub 后原生渲染
	@echo "git push 后 GitHub 原生渲染 markdown，README.md 为入口"

# ──────────────────────────────────────────────
# 集群管理（k3d - Docker 内运行 k3s，开箱即用）
# ──────────────────────────────────────────────

K3D_VERSION ?= v5.8.3

create-kind-cluster: ## 用 k3d 创建 k3s 集群（Docker 内，开箱即用）
	@echo "=== 创建 k3d 集群: $(K3D_CLUSTER_NAME) ==="; \
	if ! command -v k3d >/dev/null 2>&1; then \
		echo "安装 k3d $(K3D_VERSION)..."; \
		curl -sLo /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/download/$(K3D_VERSION)/k3d-linux-amd64 && \
		chmod +x /usr/local/bin/k3d; \
	fi; \
	ULIMIT=$$(docker run --rm alpine:latest sh -c 'ulimit -n' 2>/dev/null || echo 1024); \
	if [ "$$ULIMIT" -lt 65536 ]; then \
		echo "Docker nofile ulimit=$$ULIMIT（k3s 需要 ≥65536），自动配置..."; \
		python3 -c 'import json; cfg=json.load(open("/etc/docker/daemon.json")); cfg.setdefault("default-ulimits",{})["nofile"]={"Name":"nofile","Soft":65536,"Hard":131072}; json.dump(cfg,open("/etc/docker/daemon.json","w"),indent=2)' && systemctl restart docker 2>/dev/null; \
		until docker info >/dev/null 2>&1; do sleep 1; done; \
	fi; \
	if k3d cluster list 2>/dev/null | grep -q '^$(K3D_CLUSTER_NAME) '; then \
		echo "集群 $(K3D_CLUSTER_NAME) 已存在，跳过创建"; \
	else \
		TGT="$(KUBECONFIG_TARGET)"; \
		PORT="$(KIND_API_PORT)"; \
		if [ "$$PORT" = "0" ]; then \
			PORT=$$(python3 -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()'); \
		fi; \
		echo "目标 kubeconfig: $$TGT，API 端口: $$PORT"; \
		echo "启动集群，映射端口 127.0.0.1:$${PORT}:6443..."; \
		k3d cluster create $(K3D_CLUSTER_NAME) \
			--port 127.0.0.1:$${PORT}:6443@server:0 \
			--k3s-arg '--disable=traefik@server:0' \
			--kubeconfig-update-default=false || { \
			echo "k3d 创建失败（可能此环境不支持嵌套容器化运行 k3s）"; \
			echo "提示: 当前环境已有 k3s 集群，可用以下命令直接使用："; \
			echo "  make use-existing-cluster"; \
			exit 1; }; \
		echo "等待 k3d API 就绪..."; \
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do \
			if k3d kubeconfig get $(K3D_CLUSTER_NAME) >/dev/null 2>&1; then \
				break; \
			fi; \
			if [ "$$i" -eq 15 ]; then \
				echo "错误: k3d API 未能就绪"; \
				k3d cluster delete $(K3D_CLUSTER_NAME) >/dev/null 2>&1; \
				exit 1; \
			fi; \
			sleep 2; \
		done; \
		echo "写入 k3d 集群到 $$TGT..."; \
		K3D_CFG=$$(mktemp); \
		k3d kubeconfig get $(K3D_CLUSTER_NAME) > $$K3D_CFG; \
		SERVER="https://127.0.0.1:$${PORT}"; \
		CA_FILE=$$(mktemp); \
		CERT_FILE=$$(mktemp); \
		KEY_FILE=$$(mktemp); \
		grep 'certificate-authority-data:' $$K3D_CFG | sed 's/.*certificate-authority-data: //' | base64 -d > $$CA_FILE; \
		grep 'client-certificate-data:' $$K3D_CFG | sed 's/.*client-certificate-data: //' | base64 -d > $$CERT_FILE; \
		grep 'client-key-data:' $$K3D_CFG | sed 's/.*client-key-data: //' | base64 -d > $$KEY_FILE; \
		kubectl config --kubeconfig $$TGT set-cluster k3d-$(K3D_CLUSTER_NAME) \
			--server=$$SERVER --embed-certs --certificate-authority=$$CA_FILE >/dev/null; \
		kubectl config --kubeconfig $$TGT set-credentials admin@k3d-$(K3D_CLUSTER_NAME) \
			--embed-certs --client-certificate=$$CERT_FILE --client-key=$$KEY_FILE >/dev/null; \
		kubectl config --kubeconfig $$TGT set-context k3d-$(K3D_CLUSTER_NAME) \
			--cluster=k3d-$(K3D_CLUSTER_NAME) --user=admin@k3d-$(K3D_CLUSTER_NAME) >/dev/null; \
		kubectl config --kubeconfig $$TGT use-context k3d-$(K3D_CLUSTER_NAME) >/dev/null; \
		rm -f $$K3D_CFG $$CA_FILE $$CERT_FILE $$KEY_FILE; \
		echo ""; \
		echo "=== 集群就绪: $(K3D_CLUSTER_NAME) ==="; \
		sleep 5; \
		kubectl cluster-info; \
		echo ""; \
		echo "=== 集群验证 ==="; \
		kubectl get nodes -o wide 2>&1 || echo "（节点未就绪，可以等几秒再试）"; \
		echo ""; \
		echo "# 切换集群:"; \
		echo "  kubectl config use-context k3d-$(K3D_CLUSTER_NAME)   # 切到 k3d"; \
		echo "  kubectl config use-context default                    # 切回宿主"; \
		echo ""; \
		echo "# 删除: make delete-kind-cluster KIND_CLUSTER_NAME=$(KIND_CLUSTER_NAME)"; \
	fi

use-existing-cluster: ## 使用已有的 k3s 集群
	@echo "=== 配置已有集群（k3s） ==="; \
	mkdir -p $(HOME)/.kube; \
	if [ -f /etc/rancher/k3s/k3s.yaml ]; then \
		cp /etc/rancher/k3s/k3s.yaml $(HOME)/.kube/k3s.config; \
		cp /etc/rancher/k3s/k3s.yaml $(HOME)/.kube/config; \
		echo "已配置 k3s 集群"; \
		echo "独立 kubeconfig: ~/.kube/k3s.config"; \
		echo "默认 kubeconfig: ~/.kube/config"; \
		echo ""; \
		kubectl cluster-info; \
		echo ""; \
		kubectl get nodes -o wide; \
	elif kubectl cluster-info > /dev/null 2>&1; then \
		echo "已存在可用的 Kubernetes 集群"; \
		kubectl cluster-info; \
	else \
		echo "未检测到已有集群，请先安装 Kubernetes"; \
		echo "可尝试: make create-kind-cluster"; \
	fi

delete-kind-cluster: ## 删除 k3d 集群并清理 kubeconfig
	@echo "=== 删除集群: $(K3D_CLUSTER_NAME) ==="; \
	k3d cluster delete $(K3D_CLUSTER_NAME) 2>/dev/null || true; \
	TGT="$(KUBECONFIG_TARGET)"; \
	if [ -f "$$TGT" ]; then \
		CURRENT=$$(kubectl config --kubeconfig $$TGT current-context 2>/dev/null); \
		if [ "$$CURRENT" = "k3d-$(K3D_CLUSTER_NAME)" ]; then \
			kubectl config --kubeconfig $$TGT use-context default >/dev/null 2>&1 || true; \
		fi; \
		kubectl config --kubeconfig $$TGT delete-context k3d-$(K3D_CLUSTER_NAME) 2>/dev/null || true; \
		kubectl config --kubeconfig $$TGT delete-cluster k3d-$(K3D_CLUSTER_NAME) 2>/dev/null || true; \
		kubectl config --kubeconfig $$TGT unset users.admin@k3d-$(K3D_CLUSTER_NAME) 2>/dev/null || true; \
		echo "已清理 $$TGT 中的 k3d 条目"; \
	fi

kind-kubecfg: ## 打印当前 kubeconfig 路径
	@echo "$(KUBECONFIG_TARGET)"

helm-install: create-kind-cluster ## 创建集群后用 Helm 安装 kagent
	@echo "=== Helm 安装 kagent ==="
	@kubectl create namespace $(HELM_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install kagent-crds \
		oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
		--version $(KAGENT_VERSION) \
		--namespace $(HELM_NAMESPACE) --create-namespace
	helm upgrade --install kagent \
		oci://ghcr.io/kagent-dev/kagent/helm/kagent \
		--version $(KAGENT_VERSION) \
		--namespace $(HELM_NAMESPACE) \
		--values platform/helm/kagent/values.yaml
