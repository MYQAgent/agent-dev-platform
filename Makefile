# myqagent-dev-platform
# 文档查看与常用命令统一入口。Run `make help` for available targets.

.PHONY: help docs docs-http docs-mkdocs docs-vitepress docs-github

PORT ?= 3080

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
