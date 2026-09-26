# kubectl Context 命令速查

## 查看

| 命令 | 作用 |
|------|------|
| `kubectl config current-context` | 当前 context |
| `kubectl config get-contexts` | 所有 context 列表 |
| `kubectl config view --minify` | 当前配置摘要 |

## 切换

| 命令 | 作用 |
|------|------|
| `kubectl config use-context <name>` | 永久切换默认 context |
| `--context <name>` | 单条命令切换（推荐） |

## Namespace

| 命令 | 作用 |
|------|------|
| `--namespace <ns>` / `-n <ns>` | 指定 namespace |
| `kubectl config set-context --current --namespace=<ns>` | 持久化 namespace |

## 安全

- 写操作前先跑 `check-context.sh`
- 生产集群操作优先用 `--context` 显式指定