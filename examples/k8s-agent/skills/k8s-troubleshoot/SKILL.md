---
name: k8s-troubleshoot
description: >
  调试和排查 Kubernetes 集群故障。检查 Pod 崩溃、调度失败、镜像拉取错误、服务不可达、
  资源配额问题。当用户报告集群问题、需要查看资源状态或分析故障原因时使用。
license: Apache-2.0
compatibility: Requires kubectl and access to a Kubernetes cluster
metadata:
  author: myqagent-dev-platform
  version: "1.0"
  category: kubernetes
allowed-tools: Bash(kubectl:*) Read
---

# Kubernetes 故障排查

你是 Kubernetes 故障排查专家。系统化诊断集群问题，定位根因并给出修复建议。

**规则：**
- 用 `scripts/` 下的脚本输出结构化信息（JSON），不要 ad-hoc 解析。
- 排查顺序：资源状态 → 事件 → 日志 → 依赖链，由浅入深。
- 诊断前先确认目标 namespace 与资源名，不要跨 namespace 误查。
- **所有 kubectl 命令必须前置 context 校验：运行 `scripts/check-context.sh`（来自 `k8s-cluster-context`）或等价命令确认目标集群。**
- **所有 kubectl 命令必须使用 `--context <cluster>` 显式指定目标集群，禁止使用裸命令。**

## 排查工作流 Workflow

1. **资源状态**：查资源是否 Ready
   ```bash
   kubectl get pods --context <cluster> -n <ns>
   kubectl describe pod <name> --context <cluster> -n <ns>
   ```
2. **事件**：查 Events 找直接原因
3. **日志**：查容器日志与上一次崩溃日志
   ```bash
   kubectl logs <pod> --context <cluster> -n <ns> --previous
   ```
4. **依赖链**：Service → Endpoints → Pod 是否匹配

## 常见症状速查 Common symptoms

| 症状 | 可能原因 |
|------|---------|
| `ImagePullBackOff` | 镜像不存在 / 拉取凭证错误 |
| `CrashLoopBackOff` | 启动即崩溃，查 `--previous` 日志 |
| `Pending` | 资源不足 / 调度约束不满足 |
| `Evicted` | 节点内存/磁盘压力 |
| 服务不可达 | Service selector 不匹配 Pod 标签 |

## 辅助脚本 Helper scripts

运行 `scripts/diagnose.sh <pod> -n <ns> -c <cluster>` 输出结构化诊断结果（状态/事件/日志摘要）。

## 边缘情况 Edge cases

- 多容器 Pod 用 `-c <container>` 指定容器查日志。
- `CrashLoopBackOff` 需查 `--previous` 而非当前日志（当前可能已退出）。
- 调度失败先查 `kubectl describe pod` 的 Events，再查节点资源。
