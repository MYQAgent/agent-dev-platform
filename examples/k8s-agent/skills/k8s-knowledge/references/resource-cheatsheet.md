# Kubernetes 资源速查

## Deployment 常用字段

| 路径 | 类型 | 说明 |
|------|------|------|
| `spec.replicas` | int | 副本数 |
| `spec.selector.matchLabels` | map | 选择器 |
| `spec.template.spec.containers` | [] | 容器列表 |
| `spec.strategy.type` | string | RollingUpdate / Recreate |
| `spec.minReadySeconds` | int | 就绪等待 |

## Service 类型

| type | 说明 |
|------|------|
| ClusterIP | 集群内访问（默认） |
| NodePort | 节点端口 |
| LoadBalancer | 云负载均衡 |

## 探针 Probes

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
```

## 资源限制 Resources

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```
