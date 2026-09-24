# 安全审计检查清单 Security Checklist

## RBAC

- [ ] 无默认 ServiceAccount 绑定 cluster-admin
- [ ] 无 `*` 对资源与 namespace 同时通配
- [ ] Role 而非 ClusterRole 用于 namespace 内授权
- [ ] 服务账号权限最小化

## Secret 管理

- [ ] Secret 未明文提交到 Git
- [ ] 使用外部密钥管理（ESO / Vault / Sealed Secrets）
- [ ] 镜像拉取凭证独立管理

## 容器安全

- [ ] `runAsNonRoot: true`
- [ ] `allowPrivilegeEscalation: false`
- [ ] 无 privileged 容器
- [ ] 使用只读根文件系统（`readOnlyRootFilesystem`，如适用）
- [ ] 设置资源 `requests` 与 `limits`

## 网络

- [ ] 配置 NetworkPolicy（默认拒绝 + 白名单）
- [ ] 无 LoadBalancer 暴露不必要端口

## API 版本

- [ ] 无 deprecated API（extensions/v1beta1、apps/v1beta1 等）
- [ ] 使用稳定版本 API
