# myqagent-dev-platform
# 文档查看与常用命令统一入口。Run `make help` for available targets.

.PHONY: help docs docs-http docs-mkdocs docs-vitepress docs-github
.PHONY: create-kind-cluster delete-kind-cluster kind-kubecfg helm-install

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
	if docker ps --format '{{.Names}}' | grep -q '^$(KIND_NODE_NAME)$$'; then \
		echo "集群容器 $(KIND_NODE_NAME) 已存在，跳过创建"; \
	else \
		docker run -d \
			--name $(KIND_NODE_NAME) \
			--privileged \
			--restart=on-failure:3 \
			-p 127.0.0.1:$(KIND_API_PORT):6443 \
			$(KIND_NODE_IMAGE); \
		echo "等待容器就绪..."; \
		sleep 8; \
		CONTAINER_IP=$$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(KIND_NODE_NAME)); \
		echo "容器 IP: $$CONTAINER_IP"; \
		echo "=== 初始化集群（kubeadm init） ==="; \
		docker exec $(KIND_NODE_NAME) kubeadm init \
			--kubernetes-version=v1.32.2 \
			--apiserver-advertise-address=$$CONTAINER_IP \
			--apiserver-cert-extra-sans=127.0.0.1 \
			--pod-network-cidr=10.244.0.0/16 \
			--service-cidr=10.96.0.0/12 \
			--skip-phases=addon/kube-proxy; \
		echo "=== 安装 CNI（flannel） ==="; \
		docker exec $(KIND_NODE_NAME) kubectl --kubeconfig=/etc/kubernetes/admin.conf \
			apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml; \
		echo "=== 提取 kubeconfig ==="; \
		mkdir -p $(HOME)/.kube; \
		docker exec $(KIND_NODE_NAME) cat /etc/kubernetes/admin.conf > $(HOME)/.kube/$(KIND_CLUSTER_NAME).config; \
		sed "s|server: https://.*:6443|server: https://127.0.0.1:$(KIND_API_PORT)|g" $(HOME)/.kube/$(KIND_CLUSTER_NAME).config > $(HOME)/.kube/config; \
		echo "=== 集群就绪 ==="; \
		kubectl cluster-info; \
	fi

delete-kind-cluster: ## 删除 Kind 集群容器
	@echo "=== 删除集群容器: $(KIND_NODE_NAME) ==="
	@docker rm -f $(KIND_NODE_NAME) 2>/dev/null || echo "容器不存在"

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
