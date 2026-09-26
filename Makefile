# myqagent-dev-platform
# 文档查看与常用命令统一入口。Run `make help` for available targets.

.PHONY: help docs docs-http docs-mkdocs docs-vitepress docs-github
.PHONY: create-kind-cluster delete-kind-cluster kind-kubecfg helm-install use-existing-cluster

PORT              ?= 3080
KIND_CLUSTER_NAME ?= kagent
KIND_NODE_IMAGE   ?= kindest/node:v1.32.2
KIND_NODE_NAME    ?= $(KIND_CLUSTER_NAME)-control-plane
KIND_API_PORT     ?= 8443
HELM_NAMESPACE    ?= kagent
KAGENT_VERSION    ?= 1.0.0-alpha3

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
# 集群管理（纯 docker run，无需 kind CLI）
# ──────────────────────────────────────────────

create-kind-cluster: ## 用 docker run 创建 Kind 集群（纯 Docker 方式）
	@echo "=== 创建 Kind 集群: $(KIND_CLUSTER_NAME) ==="; \
	CONTAINER_EXISTS=$$(docker ps -a --format '{{.Names}}' | grep -q '^$(KIND_NODE_NAME)$$' && echo 1 || echo 0); \
	CONTAINER_RUNNING=$$(docker ps --format '{{.Names}}' | grep -q '^$(KIND_NODE_NAME)$$' && echo 1 || echo 0); \
	if [ "$$CONTAINER_RUNNING" = "1" ]; then \
		echo "集群容器 $(KIND_NODE_NAME) 已在运行，跳过创建"; \
	else \
		if [ "$$CONTAINER_EXISTS" = "1" ]; then \
			echo "清理残留容器 $(KIND_NODE_NAME)..."; \
			docker rm -f $(KIND_NODE_NAME) > /dev/null 2>&1; \
			rm -f $(HOME)/.kube/$(KIND_CLUSTER_NAME).config; \
			echo "已清理"; \
		fi; \
		docker run -d \
			--name $(KIND_NODE_NAME) \
			--privileged \
			--restart=on-failure:3 \
			--hostname $(KIND_NODE_NAME) \
			--tmpfs /tmp \
			--tmpfs /run \
			-v /lib/modules:/lib/modules:ro \
			-p 127.0.0.1:$(KIND_API_PORT):6443 \
			$(KIND_NODE_IMAGE) 2>&1; \
		echo "等待容器就绪..."; \
		for i in 1 2 3 4 5 6 7 8 9 10; do \
			CONTAINER_STATUS=$$(docker inspect -f '{{.State.Status}}' $(KIND_NODE_NAME) 2>/dev/null); \
			if [ "$$CONTAINER_STATUS" = "running" ]; then \
				CONTAINER_IP=$$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(KIND_NODE_NAME)); \
				echo "容器 IP: $$CONTAINER_IP"; \
				break; \
			elif [ "$$CONTAINER_STATUS" = "exited" ]; then \
				echo "错误: Kind 节点容器启动失败（此环境可能不支持嵌套容器化运行 Kind）"; \
				docker rm -f $(KIND_NODE_NAME) > /dev/null 2>&1; \
				echo ""; \
				echo "提示: 当前环境已有 k3s 集群，可用以下命令直接使用："; \
				echo "  make use-existing-cluster"; \
				exit 1; \
			fi; \
			if [ "$$i" -eq 10 ]; then \
				echo "错误: 容器未能在 20 秒内就绪"; \
				docker rm -f $(KIND_NODE_NAME) > /dev/null 2>&1; \
				exit 1; \
			fi; \
			sleep 2; \
		done; \
		echo "=== 初始化集群（kubeadm init） ==="; \
		if ! docker exec $(KIND_NODE_NAME) kubeadm init \
			--kubernetes-version=v1.32.2 \
			--apiserver-advertise-address=$$CONTAINER_IP \
			--apiserver-cert-extra-sans=127.0.0.1 \
			--pod-network-cidr=10.244.0.0/16 \
			--service-cidr=10.96.0.0/12 \
			--skip-phases=addon/kube-proxy; then \
			echo "错误: kubeadm init 失败"; \
			docker rm -f $(KIND_NODE_NAME) > /dev/null 2>&1; \
			exit 1; \
		fi; \
		echo "=== 安装 CNI（flannel） ==="; \
		docker exec $(KIND_NODE_NAME) kubectl --kubeconfig=/etc/kubernetes/admin.conf \
			apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml; \
		echo "=== 提取 kubeconfig ==="; \
		mkdir -p $(HOME)/.kube; \
		docker exec $(KIND_NODE_NAME) cat /etc/kubernetes/admin.conf > $(HOME)/.kube/$(KIND_CLUSTER_NAME).raw; \
		CTX_NAME=$$(grep 'current-context:' $(HOME)/.kube/$(KIND_CLUSTER_NAME).raw | awk '{print $$2}'); \
		sed "s|server: https://.*:6443|server: https://127.0.0.1:$(KIND_API_PORT)|g" \
			$(HOME)/.kube/$(KIND_CLUSTER_NAME).raw > $(HOME)/.kube/$(KIND_CLUSTER_NAME).config; \
		rm -f $(HOME)/.kube/$(KIND_CLUSTER_NAME).raw; \
		if [ -f $(HOME)/.kube/config ]; then \
			echo "=== 合并 kubeconfig（保留已有 context） ==="; \
			KUBECONFIG=$(HOME)/.kube/config:$(HOME)/.kube/$(KIND_CLUSTER_NAME).config \
			kubectl config view --flatten > $(HOME)/.kube/config.new 2>/dev/null && \
			mv $(HOME)/.kube/config.new $(HOME)/.kube/config; \
		else \
			cp $(HOME)/.kube/$(KIND_CLUSTER_NAME).config $(HOME)/.kube/config; \
		fi; \
		echo ""; \
		echo "=== 集群就绪: $(KIND_CLUSTER_NAME) ==="; \
		kubectl cluster-info --context $$CTX_NAME 2>/dev/null || kubectl cluster-info; \
		echo ""; \
		echo "=== 集群验证 ==="; \
		kubectl get nodes --context $$CTX_NAME -o wide; \
		echo ""; \
		echo "# 独立 kubeconfig: ~/.kube/$(KIND_CLUSTER_NAME).config"; \
		echo "# 切换 context:  kubectl config use-context $$CTX_NAME"; \
		echo "# 删除集群:     make delete-kind-cluster KIND_CLUSTER_NAME=$(KIND_CLUSTER_NAME)"; \
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

delete-kind-cluster: ## 删除 Kind 集群容器并清理 kubeconfig
	@echo "=== 删除集群容器: $(KIND_NODE_NAME) ==="; \
	docker rm -f $(KIND_NODE_NAME) 2>/dev/null || echo "容器不存在"; \
	echo "=== 清理 kubeconfig ==="; \
	CFG=$(HOME)/.kube/$(KIND_CLUSTER_NAME).config; \
	if [ -f $$CFG ]; then \
		CTX=$$(grep 'current-context:' $$CFG | awk '{print $$2}'); \
		rm -f $$CFG; \
		echo "已删除: $$CFG"; \
		if [ -n "$$CTX" ] && grep -q "$$CTX" $(HOME)/.kube/config 2>/dev/null; then \
			kubectl config delete-context $$CTX 2>/dev/null || true; \
			kubectl config delete-cluster $$(echo $$CTX | sed 's/.*@//') 2>/dev/null || true; \
			echo "已移除 context: $$CTX"; \
		fi; \
	else \
		echo "kubeconfig 文件不存在: $$CFG"; \
	fi

kind-kubecfg: ## 打印集群 kubeconfig 路径
	@echo "$(HOME)/.kube/$(KIND_CLUSTER_NAME).config"

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
