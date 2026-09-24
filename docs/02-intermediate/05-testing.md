# 测试与 evals

> Test skills with evals.

---

## 核心命令 Core commands

```bash
# 校验 skill 格式
npx skills-ref validate ./skills/k8s-knowledge

# 运行 evals（用子 agent 执行每个场景并评分）
# 见下方 evals.json 说明
```

---

## evals.json 结构 Structure

每个 skill 的 `evals/evals.json` 定义评估场景：

```json
{
  "evals": [
    {
      "id": "k8s-knowledge-001",
      "prompt": "生成一个名为 web 的 Deployment，3 个副本，使用 nginx:1.25 镜像",
      "expectations": [
        "包含 apiVersion: apps/v1",
        "kind 是 Deployment",
        "replicas 为 3",
        "镜像为 nginx:1.25"
      ]
    }
  ]
}
```

每个 expectation 是独立的通过/失败检查。

---

## 运行 evals 的方法 Running evals

参考 fluxcd 的做法：为每个 eval 派生子 agent，让它只加载 skill 并完成任务，再对输出评分：

```
对每个 eval：
  1. 子 agent 加载 skills/<name>/SKILL.md（不告知期望）
  2. 子 agent 执行 eval.prompt
  3. 对照 expectations 数组评分（每个 pass/fail）
  4. 汇总为 scorecard：eval id + 通过/失败数
```

> 子 agent **不能被告知期望**——它必须仅靠 skill workflow 产出正确结果。

---

## 测试夹具 Test fixtures

在 `tests/<skill-name>/` 放置测试夹具，覆盖不同场景：

```
tests/k8s-knowledge/
├── basic-deployment/        # 基础场景
└── statefulset/             # 有状态场景
```

脚本针对夹具运行，验证输出。

---

## 评分输出示例 Scorecard

```
k8s-knowledge-001: 4/4 passed
k8s-knowledge-002: 2/3 passed (missing: service selector)
k8s-knowledge-003: 3/3 passed
```

---

## 下一步 Next

- 最佳实践 → [../04-best-practices/skill-design.md](../04-best-practices/skill-design.md)
- 完整 evals 示例 → [../../examples/k8s-agent/](../../examples/k8s-agent/)
