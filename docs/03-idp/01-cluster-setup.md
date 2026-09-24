# 集群搭建：controller + Substrate

> Set up the full platform cluster — 成本级别 ⑤（贡献者/平台路径，重）

---

## 核心命令 Core commands

```bash
# kagent 仓库提供的一键脚本（从零搭建 dev cluster）
cd /path/to/kagent
./scripts/setup-cluster/setup-cluster.sh
```

> 这是贡献者路径，10 步。仅想跑 agent 请用 [消费者路径](../01-basics/04-run-agent.md)。

---

## 为什么这么重？Why so heavy?

v2 强制依赖 **Substrate**（唯一 compute backend），它需要安全基础设施：

```
setup-cluster.sh 十步
─────────────────────
1/10  Kind 集群 + 本地 registry (:5001)
2/10  kubectl-ate（铸造 CA 与 JWT pool 的工具）
3/10  Substrate CRDs + substrate（Helm）
4/10  5 个 CA/JWT pool（服务 DNS / pod 身份 / actor 身份 / egress MITM）
5/10  Actor 身份 CA 证书 + ate-api authentication ConfigMap
6/10  kagent controller（启用 substrate，指向 ate-system）
7/10  构建并替换 controller + UI 镜像（本地改动生效）
8/10  构建 agent runtime 镜像（Go ADK，digest 引用）
9/10  Harness + AgentTemplate 对（让 app 里有个 agent）
10/10 port-forward UI(:8080) + controller(:8083)
```

---

## 关键依赖清单 Dependencies

| 依赖 | 版本 | 说明 |
|------|------|------|
| Substrate | v0.2.0-beta5 | 唯一 compute backend |
| kubectl-ate | 同上版本 | 铸造 CA/JWT pool |
| Kind / kubectl / Helm | 最新 | 集群与安装 |
| Go / Docker Buildx | 贡献者路径 | 构建镜像 |

---

## Substrate 关键概念 Substrate concepts

| 概念 | 作用 |
|------|------|
| Actor | 承载一个 agent 运行时的工作负载 |
| WorkerPool | Actor 运行的工作节点池 |
| 快照 snapshot | Actor 的持久化状态（golden snapshot = 初始模板快照） |
| DurableDir | 跨 Actor 替换存活的状态目录 |

kagent 的 `Harness.spec.substrate` 需要：
- `workerPoolRef`：指向 WorkerPool
- `snapshotPolicy.location`：快照存储位置（如 `s3://ate-snapshots/kagent`）

---

## 常见坑 Pitfalls

- **kubectl-ate 返回成功 ≠ secret 可读**：脚本里要轮询 secret 就绪，否则下一步挂载失败。
- **Substrate 要求 digest 引用**：agent runtime 镜像必须 `@sha256:...`，tag 不行。
- **Go ADK 才能从快照恢复**：Python runtime 在 Actor 恢复时可能 SIGILL，静态 Go 二进制更稳。
- **template 未被 Harness 接纳**：创建成功但什么都不做，是最易困惑的状态。

---

## 最小可用验证 Verify

```bash
# agent 进入 Ready 说明 Substrate 已启动 golden actor 并快照
kubectl get agenttemplate -n kagent <name> \
  -o jsonpath='{.status.harnesses[0].conditions[?(@.type=="Ready")].status}'
# 期望 True
```

---

## 下一步 Next

- CI/CD 流水线 → [02-pipelines.md](02-pipelines.md)
- 治理 → [03-governance.md](03-governance.md)
