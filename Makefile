# myqagent-dev-platform
# 文档查看与常用命令统一入口。Run `make help` for available targets.

.PHONY: help docs docs-http docs-mkdocs docs-vitepress docs-github
.PHONY: create-k3d-cluster delete-k3d-cluster k3d-kubecfg helm-install use-existing-cluster
.PHONY: create-kind-cluster delete-kind-cluster kind-kubecfg
.PHONY: install-kubectl-ate install-substrate install-kagent mirror

PORT              ?= 3080
K3D_CLUSTER_NAME  ?= kagent
# 0=自动检测空闲端口，可指定如 K3D_API_PORT=8443
K3D_API_PORT      ?= 0
K3S_IMAGE         ?= rancher/k3s:v1.37.0-k3s1
HELM_NAMESPACE    ?= kagent
KAGENT_VERSION    ?= 1.0.0-alpha3
SUBSTRATE_VERSION ?= 0.2.0-beta5
MODEL_PROVIDER    ?= openAI

# 写入目标：设了 $KUBECONFIG 则用它，否则默认 ~/.kube/config
KUBECONFIG_OUT ?= $(if $(KUBECONFIG),$(firstword $(subst :, ,$(KUBECONFIG))),$(HOME)/.kube/config)

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

create-k3d-cluster: ## 用 k3d 创建 k3s 集群，内置 registry（Docker 内，开箱即用）
	@echo "=== 创建 k3d 集群: $(K3D_CLUSTER_NAME) ==="; \
	if ! command -v k3d >/dev/null 2>&1; then \
		echo "安装 k3d $(K3D_VERSION)..."; \
		curl -sLo /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/download/$(K3D_VERSION)/k3d-linux-amd64 && \
		chmod +x /usr/local/bin/k3d; \
	fi; \
	INOTIFY=$$(docker run --rm alpine:latest sh -c 'cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo 128'); \
	if [ "$$INOTIFY" -lt 1024 ]; then \
		echo "inotify max_user_instances=$$INOTIFY（k3s 需要 ≥1024），将在容器内自动修复"; \
	fi; \
	if k3d cluster list 2>/dev/null | grep -q '^$(K3D_CLUSTER_NAME) '; then \
		echo "集群 $(K3D_CLUSTER_NAME) 已存在，跳过创建"; \
	else \
		TGT="$(KUBECONFIG_OUT)"; \
		PORT="$(K3D_API_PORT)"; \
		if [ "$$PORT" = "0" ]; then \
			PORT=$$(python3 -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()'); \
		fi; \
		echo "目标 kubeconfig: $$TGT，API 端口: $$PORT"; \
		echo "启动集群，内置 registry（宿主机 localhost:5000 = 集群内 k3d-$(K3D_CLUSTER_NAME)-registry:5000）..."; \
		k3d cluster create $(K3D_CLUSTER_NAME) \
			--image $(K3S_IMAGE) \
			--registry-create k3d-$(K3D_CLUSTER_NAME)-registry:0.0.0.0:5000 \
			--port 127.0.0.1:$${PORT}:6443@server:0 \
			--k3s-arg '--disable=traefik@server:0' \
			--k3s-arg '--kube-apiserver-arg=--runtime-config=certificates.k8s.io/v1beta1=true@server:0' \
			--kubeconfig-update-default=false || { \
			echo "k3d 创建失败"; \
			exit 1; }; \
		echo "修复容器 inotify 限制（CRI 加载需要）..."; \
		docker exec k3d-$(K3D_CLUSTER_NAME)-server-0 sh -c \
			'sysctl -w fs.inotify.max_user_instances=1024 fs.inotify.max_user_watches=1048576' >/dev/null 2>&1; \
		echo "配置 containerd 镜像加速（国内源 + 内置 registry）..."; \
		printf 'mirrors:\n  localhost:5000:\n    endpoint:\n      - "http://k3d-$(K3D_CLUSTER_NAME)-registry:5000"\n  docker.io:\n    endpoint:\n      - "https://docker.1ms.run"\n  ghcr.io:\n    endpoint:\n      - "https://ghcr.nju.edu.cn"\n  registry.k8s.io:\n    endpoint:\n      - "https://docker.1ms.run"\n' > /tmp/k3d-registries.yaml; \
		docker cp /tmp/k3d-registries.yaml k3d-$(K3D_CLUSTER_NAME)-server-0:/etc/rancher/k3s/registries.yaml; \
		rm -f /tmp/k3d-registries.yaml; \
		echo "重启 k3s 使修复生效..."; \
		docker restart k3d-$(K3D_CLUSTER_NAME)-server-0 >/dev/null; \
		echo "等待 k3s 就绪..."; \
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do \
			if docker exec k3d-$(K3D_CLUSTER_NAME)-server-0 sh -c \
				'kubectl get nodes 2>/dev/null | grep -q Ready' >/dev/null 2>&1; then \
				echo "节点已就绪"; \
				break; \
			fi; \
			if [ "$$i" -eq 20 ]; then \
				echo "错误: 节点未能就绪"; \
				k3d cluster delete $(K3D_CLUSTER_NAME) >/dev/null 2>&1; \
				exit 1; \
			fi; \
			sleep 3; \
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
		for F in "$$TGT" "/etc/rancher/k3s/k3s.yaml"; do \
			if [ -f "$$F" ]; then \
				kubectl config --kubeconfig $$F set-cluster k3d-$(K3D_CLUSTER_NAME) \
					--server=$$SERVER --embed-certs --certificate-authority=$$CA_FILE >/dev/null; \
				kubectl config --kubeconfig $$F set-credentials admin@k3d-$(K3D_CLUSTER_NAME) \
					--embed-certs --client-certificate=$$CERT_FILE --client-key=$$KEY_FILE >/dev/null; \
				kubectl config --kubeconfig $$F set-context k3d-$(K3D_CLUSTER_NAME) \
					--cluster=k3d-$(K3D_CLUSTER_NAME) --user=admin@k3d-$(K3D_CLUSTER_NAME) >/dev/null; \
				kubectl config --kubeconfig $$F use-context k3d-$(K3D_CLUSTER_NAME) >/dev/null; \
			fi; \
		done; \
		rm -f $$K3D_CFG $$CA_FILE $$CERT_FILE $$KEY_FILE; \
		echo ""; \
		echo "=== 集群就绪: $(K3D_CLUSTER_NAME) ==="; \
		kubectl cluster-info; \
		echo ""; \
		echo "=== 集群验证 ==="; \
		kubectl get nodes -o wide; \
		echo ""; \
		echo "# 切换集群:"; \
		echo "  kubectl config use-context k3d-$(K3D_CLUSTER_NAME)   # 切到 k3d"; \
		echo "  kubectl config use-context default                    # 切回宿主"; \
		echo ""; \
		echo "# 删除: make delete-k3d-cluster K3D_CLUSTER_NAME=$(K3D_CLUSTER_NAME)"; \
		echo ""; \
		echo "# 内置 registry:"; \
		echo "  localhost:5000 = 集群内 k3d-$(K3D_CLUSTER_NAME)-registry:5000（自动配置）"; \
		echo "  oras push localhost:5000/my-image:tag ./dir"; \
		echo "  docker push localhost:5000/my-image:tag"; \
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
		echo "可尝试: make create-k3d-cluster"; \
	fi

delete-k3d-cluster: ## 删除 k3d 集群并清理 kubeconfig
	@echo "=== 删除集群: $(K3D_CLUSTER_NAME) ==="; \
	k3d cluster delete $(K3D_CLUSTER_NAME) 2>/dev/null || true; \
	TGT="$(KUBECONFIG_OUT)"; \
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

# ── 兼容旧名 ──
create-kind-cluster: create-k3d-cluster
delete-kind-cluster: delete-k3d-cluster
kind-kubecfg: k3d-kubecfg

mirror: ## 配置国内镜像加速（tools/mirror.sh）
	@bash tools/mirror.sh

k3d-kubecfg: ## 打印当前 kubeconfig 路径
	@echo "$(KUBECONFIG_OUT)"

# ──────────────────────────────────────────────
# kagent 安装（依赖 create-kind-cluster）
# ──────────────────────────────────────────────

SUBSTRATE_CHART      ?= oci://ghcr.io/kagent-dev/substrate/helm/substrate
SUBSTRATE_CRDS_CHART ?= oci://ghcr.io/kagent-dev/substrate/helm/substrate-crds
KAGENT_CHART         ?= oci://ghcr.io/kagent-dev/kagent/helm/kagent
KAGENT_CRDS_CHART    ?= oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds

install-kubectl-ate: ## 安装 kubectl-ate（Substrate CLI）
	@if ! command -v kubectl-ate >/dev/null 2>&1; then \
		echo "安装 kubectl-ate $(SUBSTRATE_VERSION)..."; \
		UNAME_S=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
		UNAME_M=$$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/'); \
		curl -fsSL -o /usr/local/bin/kubectl-ate \
			"https://github.com/kagent-dev/substrate/releases/download/v$(SUBSTRATE_VERSION)/kubectl-ate-$${UNAME_S}-$${UNAME_M}"; \
		chmod +x /usr/local/bin/kubectl-ate; \
		echo "kubectl-ate 已安装"; \
	fi

install-substrate: create-k3d-cluster install-kubectl-ate ## 安装 Agent Substrate
	@echo "=== 安装 Agent Substrate ==="; \
	ATE_NS=ate-system; \
	echo "1/5 安装 Substrate CRDs..."; \
	helm upgrade --install substrate-crds $(SUBSTRATE_CRDS_CHART) \
		--version $(SUBSTRATE_VERSION) \
		--namespace $$ATE_NS --create-namespace --wait >/dev/null; \
	echo "2/5 安装 Substrate 控制面（第一遍）..."; \
	helm upgrade --install substrate $(SUBSTRATE_CHART) \
		--version $(SUBSTRATE_VERSION) \
		--namespace $$ATE_NS --create-namespace \
		--set 'credentialProvider.namespacePolicies[0].atespace=$(HELM_NAMESPACE)' \
		--set 'credentialProvider.namespacePolicies[0].allowedNamespaces[0]=$(HELM_NAMESPACE)' >/dev/null; \
	echo "3/5 创建 identity 材料（CA/JWT pools）..."; \
	kubectl ate admin make-ca-pool --ca-id=1 \
		--name=service-dns-ca-pool \
		--secret-namespace=podcertificate-controller-system >/dev/null 2>&1; \
	kubectl ate admin make-ca-pool --ca-id=1 \
		--name=pod-identity-ca-pool \
		--secret-namespace=podcertificate-controller-system >/dev/null 2>&1; \
	kubectl ate admin make-jwt-pool --key-id=1 \
		--name=actor-id-jwt-pool \
		--secret-namespace=$$ATE_NS >/dev/null 2>&1; \
	kubectl ate admin make-ca-pool --ca-id=1 \
		--name=actor-id-ca-pool \
		--secret-namespace=$$ATE_NS >/dev/null 2>&1; \
	kubectl ate admin make-ca-pool --ca-id=1 \
		--name=egress-mitm-ca-pool \
		--secret-namespace=$$ATE_NS --key-type=ECDSAP256 >/dev/null 2>&1; \
	echo "4/5 提取 actor 根证书并配置认证..."; \
	ACTOR_CA_ROOT=$$(kubectl get secret actor-id-ca-pool -n $$ATE_NS \
		-o jsonpath='{.data.pool}' | base64 --decode \
		| jq -r '.CAs[0].RootCertificateDER' | base64 --decode \
		| openssl x509 -inform der -outform pem); \
	kubectl create secret generic actor-id-ca-certs -n $$ATE_NS \
		--from-literal=ca.crt="$${ACTOR_CA_ROOT}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; \
	K8S_ISSUER=$$(kubectl get --raw /.well-known/openid-configuration | jq -r .issuer); \
	AUTH_CFG=$$(mktemp); \
	printf 'actorIdentityJWTProvider: kubernetes\njwtProviders:\n- name: kubernetes\n  issuer: %s\n  audiences: [api.%s.svc]\n  certificateAuthorityFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt\n  discoveryTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token\n' \
		"$$K8S_ISSUER" "$$ATE_NS" > $$AUTH_CFG; \
	kubectl create configmap ate-api-authentication -n $$ATE_NS \
		--from-file=authentication.yaml=$$AUTH_CFG --dry-run=client -o yaml | kubectl apply -f - >/dev/null; \
	rm -f $$AUTH_CFG; \
	echo "5/5 滚动 Substrate 使 identity 生效..."; \
	helm upgrade substrate $(SUBSTRATE_CHART) \
		--version $(SUBSTRATE_VERSION) \
		--namespace $$ATE_NS --reuse-values --wait --timeout 10m >/dev/null; \
	echo "Agent Substrate 已就绪"; \
	kubectl get pods -n $$ATE_NS 2>&1 | head -12

install-kagent: ## 安装 kagent controller + UI
	@echo "=== 安装 kagent ==="; \
	if [ -z "$${OPENAI_API_KEY}" ] && [ -z "$${DEEPSEEK_API_KEY}" ]; then \
		echo "错误: 请设置模型 provider API key 环境变量"; \
		echo "  export OPENAI_API_KEY=sk-..."; \
		echo "  export DEEPSEEK_API_KEY=sk-..."; \
		exit 1; \
	fi; \
	PROVIDER_KEY=$${OPENAI_API_KEY:-$$DEEPSEEK_API_KEY}; \
	echo "1/2 安装 kagent CRDs..."; \
	helm upgrade --install kagent-crds $(KAGENT_CRDS_CHART) \
		--version $(KAGENT_VERSION) \
		--namespace $(HELM_NAMESPACE) --create-namespace --wait >/dev/null; \
	echo "2/2 安装 kagent..."; \
	helm upgrade --install kagent $(KAGENT_CHART) \
		--version $(KAGENT_VERSION) \
		--namespace $(HELM_NAMESPACE) --create-namespace --timeout 10m \
		--set 'providers.default=$(MODEL_PROVIDER)' \
		--set 'providers.$(MODEL_PROVIDER).apiKey=$${PROVIDER_KEY}' \
		--values platform/helm/kagent/values.yaml >/dev/null; \
	echo "等待 kagent 就绪..."; \
	kubectl rollout status deployment/kagent-controller -n $(HELM_NAMESPACE) --timeout=300s >/dev/null 2>&1 || true; \
	kubectl get pods -n $(HELM_NAMESPACE)

helm-install: install-substrate install-kagent ## 完整安装：Substrate → kagent
	@echo "=== 安装完成 ==="; \
	echo ""; \
	echo "kagent 控制器:"; \
	kubectl get pods -n $(HELM_NAMESPACE) -l app.kubernetes.io/component=controller; \
	echo ""; \
	echo "WorkerPool:"; \
	kubectl get workerpools -n $(HELM_NAMESPACE); \
	echo ""; \
	echo "# 打开 UI:"; \
	echo "  kubectl port-forward -n $(HELM_NAMESPACE) svc/kagent-ui 8082:8080"; \
	echo "  http://localhost:8082"; \
	echo ""; \
	echo "# 控制器 gRPC API:"; \
	echo "  kubectl port-forward -n $(HELM_NAMESPACE) svc/kagent-controller 8083:8083"
