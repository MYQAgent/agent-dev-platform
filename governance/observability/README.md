# Observability 可观测

## 结构

```
observability/
├── otel-config.yaml      # OpenTelemetry 配置
└── dashboards.json       # Grafana dashboard（占位）
```

## 说明

kagent 支持 OpenTelemetry：

- **追踪**：agent 调用链、tool 调用
- **指标**：controller 指标（ServiceMonitor）
- **日志**：harness 的 OTEL logs

本地查看 trace 可用 `make otel-local`（Jaeger，OTLP 接收端口 4317/4318，UI :16686）。

> dashboards.json 为占位，具体面板依赖组织的监控栈（Grafana/Prometheus）。
