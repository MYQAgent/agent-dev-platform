#!/bin/bash
# 配置 atelet 代理（国内网络需要）
# 用于 k3d 容器无法直接访问 Google/ghcr.io 的环境
PROXY="${HTTP_PROXY:-http://172.29.0.1:7892}"

kubectl patch daemonset -n ate-system atelet --type='json' -p="[
  {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/env/-\",\"value\":{\"name\":\"HTTP_PROXY\",\"value\":\"$PROXY\"}},
  {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/env/-\",\"value\":{\"name\":\"HTTPS_PROXY\",\"value\":\"$PROXY\"}},
  {\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/env/-\",\"value\":{\"name\":\"NO_PROXY\",\"value\":\"localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local,ate-system.svc\"}}
]" 2>&1

kubectl delete pod -n ate-system -l app=atelet --force --grace-period=0 2>/dev/null
echo "atelet 已重启，等待就绪..."
kubectl wait --for=condition=Ready pod -n ate-system -l app=atelet --timeout=120s 2>&1
