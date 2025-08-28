# Prometheus Stack Setup

## ¿Qué es kube-prometheus-stack?

kube-prometheus-stack es un paquete completo de monitoreo para Kubernetes que integra Prometheus, Grafana y Alertmanager en una sola solución. Proporciona una instalación pre-configurada y optimizada para entornos de Kubernetes, incluyendo dashboards predefinidos y reglas de alerta.

### Componentes principales

1. **Prometheus**: Sistema de monitoreo y alerta que recolecta métricas de tiempo series
2. **Grafana**: Plataforma de visualización y dashboards para métricas
3. **Alertmanager**: Gestión y enrutamiento de alertas
4. **Prometheus Operator**: Operador de Kubernetes para gestionar Prometheus
5. **kube-state-metrics**: Métricas del estado de Kubernetes
6. **node-exporter**: Métricas del sistema operativo y hardware

### Ventajas principales

- ✅ **Instalación rápida**: Stack completo pre-configurado
- ✅ **Gestión automatizada**: Prometheus Operator maneja la configuración
- ✅ **Dashboards listos**: Grafana viene con dashboards predefinidos
- ✅ **Integración nativa**: Funciona perfectamente con Kubernetes
- ✅ **Escalabilidad**: Configuración optimizada para diferentes tamaños de cluster

## Instalación

### Configuración en ArgoCD

La aplicación está configurada en ArgoCD con los siguientes parámetros:

```yaml
# argocd/applications/prometheus-stack.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus-stack
  namespace: argocd
  labels:
    project: monitoring
    phase: "3"
spec:
  project: monitoring
  sources:
    - repoURL: https://prometheus-community.github.io/helm-charts
      chart: kube-prometheus-stack
      targetRevision: 76.4.0
      helm:
        valueFiles:
          - $values/apps/prometheus-stack/kube-prometheus-stack/values.yaml
    - repoURL: https://github.com/fede-r1c0/homelab
      targetRevision: HEAD
      ref: values
      path: apps/prometheus-stack/kube-prometheus-stack
      directory:
        include: "grafana-sealedsecret.yaml"
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
```

### Configuración de recursos

El archivo `values.yaml` está optimizado para ARM64/Raspberry Pi:

```yaml
# apps/prometheus-stack/kube-prometheus-stack/values.yaml
# Prometheus optimization
prometheus:
  service:
    type: LoadBalancer
  prometheusSpec:
    retention: 1d
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 200m
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 20Gi
    scrapeInterval: 30s
    evaluationInterval: 30s

# Grafana optimization
grafana:
  replicas: 1
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 200m
  service:
    type: LoadBalancer
  admin:
    existingSecret: "grafana-secret"
    userKey: "admin-user"
    passwordKey: "admin-password"

# AlertManager optimization
alertmanager:
  service:
    type: LoadBalancer
  alertmanagerSpec:
    resources:
      requests:
        memory: 32Mi
        cpu: 25m
      limits:
        memory: 64Mi
        cpu: 50m
```

### Configuración de autenticación con Sealed Secrets

Grafana utiliza Sealed Secrets para almacenar las credenciales de administrador de forma segura:

```yaml
# apps/prometheus-stack/kube-prometheus-stack/grafana-sealedsecret.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: grafana-secret
  namespace: monitoring
spec:
  encryptedData:
    admin-password: <password-encriptado>
    admin-user: <usuario-encriptado>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: grafana
        app.kubernetes.io/part-of: kube-prometheus-stack
      name: grafana-secret
      namespace: monitoring
    type: Opaque
```

## Uso básico

### 1. Verificar la instalación

```bash
# Verificar pods del stack de monitoreo
kubectl get pods -n monitoring

# Verificar servicios expuestos
kubectl get services -n monitoring

# Verificar CRDs instalados
kubectl get crd | grep prometheus
```

### 2. Acceder a las interfaces web

#### Grafana

```bash
# Port-forward para Grafana
kubectl port-forward service/prometheus-stack-grafana 3000:80 -n monitoring

# Acceder a http://localhost:3000
# Usuario: admin
# Contraseña: (definida en el SealedSecret)
```

#### Prometheus

```bash
# Port-forward para Prometheus
kubectl port-forward service/prometheus-stack-kube-prometheus-prometheus 9090:9090 -n monitoring

# Acceder a http://localhost:9090
```

#### Alertmanager

```bash
# Port-forward para Alertmanager
kubectl port-forward service/prometheus-stack-kube-prometheus-alertmanager 9093:9093 -n monitoring

# Acceder a http://localhost:9093
```

### 3. Verificar métricas básicas

```bash
# Ver métricas de Kubernetes
kubectl get --raw /metrics

# Ver métricas de Prometheus
curl http://localhost:9090/api/v1/targets

# Ver reglas de alerta
kubectl get prometheusrules -n monitoring
```

## Configuración de monitoreo

### ServiceMonitors

Los ServiceMonitors permiten a Prometheus descubrir y scrapear servicios automáticamente:

```yaml
# example-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  namespace: monitoring
  labels:
    release: prometheus-stack
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### PodMonitors

Los PodMonitors permiten monitorear pods específicos:

```yaml
# example-podmonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: example-pod
  namespace: monitoring
  labels:
    release: prometheus-stack
spec:
  selector:
    matchLabels:
      app: example-app
  podMetricsEndpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### PrometheusRules

Las reglas de Prometheus definen alertas y grabaciones:

```yaml
# example-prometheusrule.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: example-rules
  namespace: monitoring
  labels:
    release: prometheus-stack
spec:
  groups:
  - name: example
    rules:
    - alert: HighCPUUsage
      expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.instance }}"
        description: "CPU usage is above 80% for more than 5 minutes"
```

## Dashboards de Grafana

### Dashboards predefinidos

kube-prometheus-stack incluye varios dashboards útiles:

- **Kubernetes Cluster**: Visión general del cluster
- **Kubernetes Pods**: Métricas de pods individuales
- **Kubernetes Nodes**: Métricas de nodos
- **Prometheus**: Métricas del propio Prometheus
- **Grafana**: Métricas de Grafana

### Crear dashboards personalizados

```yaml
# custom-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Custom Dashboard",
        "panels": [
          {
            "title": "Custom Panel",
            "type": "graph",
            "targets": [
              {
                "expr": "up",
                "legendFormat": "{{job}}"
              }
            ]
          }
        ]
      }
    }
```

## Configuración de alertas

### AlertmanagerConfig

Configuración para el enrutamiento de alertas:

```yaml
# alertmanager-config.yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: main
  namespace: monitoring
spec:
  route:
    receiver: 'webhook'
    group_by: ['alertname']
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 12h
  receivers:
  - name: 'webhook'
    webhookConfigs:
    - url: 'http://webhook.example.com'
      sendResolved: true
```

### Configuración de notificaciones

```yaml
# notification-config.yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: notifications
  namespace: monitoring
spec:
  route:
    receiver: 'slack'
  receivers:
  - name: 'slack'
    slackConfigs:
    - apiURL: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
      channel: '#alerts'
      title: '{{ .GroupLabels.alertname }}'
      text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

## Comandos útiles

### Verificar el estado del stack

```bash
# Verificar todos los recursos en el namespace monitoring
kubectl get all -n monitoring

# Verificar CRDs de Prometheus
kubectl get prometheus -n monitoring
kubectl get servicemonitors -n monitoring
kubectl get prometheusrules -n monitoring

# Verificar configuración de Grafana
kubectl get configmaps -n monitoring -l grafana_dashboard=1
```

### Gestión de métricas y alertas

```bash
# Ver métricas en tiempo real
kubectl logs -f -n monitoring -l app.kubernetes.io/name=prometheus

# Ver alertas activas
kubectl get prometheusrules -n monitoring -o yaml

# Ver configuración de ServiceMonitors
kubectl describe servicemonitor -n monitoring
```

### Debugging y troubleshooting

```bash
# Ver logs de Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Ver logs de Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Ver logs de Alertmanager
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager

# Ver eventos del namespace
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

## Mejores prácticas

### 1. **Configuración de recursos**

- Ajusta límites de memoria y CPU según el hardware disponible
- Monitorea el uso de almacenamiento de Prometheus
- Considera usar `retention: 1d` para homelabs para ahorrar espacio

### 2. **Seguridad**

- Usa Sealed Secrets para credenciales sensibles
- Implementa RBAC para controlar acceso a métricas
- Limita el acceso a las interfaces web con políticas de red

### 3. **Monitoreo**

- Configura alertas para fallos del stack
- Monitorea el rendimiento de Prometheus
- Revisa logs regularmente para detectar problemas

### 4. **Optimización**

- Ajusta `scrapeInterval` según las necesidades
- Usa `evaluationInterval` apropiado para las reglas
- Configura `storageSpec` con el almacenamiento adecuado

## Troubleshooting

### Problema: Prometheus no puede scrapear métricas

```bash
# Verificar estado de ServiceMonitors
kubectl get servicemonitors -n monitoring

# Verificar logs de Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Verificar configuración de targets
curl http://localhost:9090/api/v1/targets
```

### Problema: Grafana no puede conectarse a Prometheus

```bash
# Verificar configuración de Grafana
kubectl get configmap -n monitoring prometheus-stack-grafana -o yaml

# Verificar logs de Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Verificar conectividad entre servicios
kubectl exec -n monitoring deployment/prometheus-stack-grafana -- curl prometheus-stack-kube-prometheus-prometheus:9090
```

### Problema: Alertas no se envían

```bash
# Verificar configuración de Alertmanager
kubectl get alertmanagerconfig -n monitoring

# Verificar logs de Alertmanager
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager

# Verificar reglas de Prometheus
kubectl get prometheusrules -n monitoring
```

### Problema: Alto uso de recursos

```bash
# Verificar uso de recursos
kubectl top pods -n monitoring

# Ajustar límites en values.yaml
# Reducir retention y scrapeInterval si es necesario
```

## Configuración avanzada

### Configuración de almacenamiento persistente

```yaml
# storage-config.yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
          storageClassName: "local-path"
```

### Configuración de alta disponibilidad

```yaml
# ha-config.yaml
prometheus:
  prometheusSpec:
    replicas: 2
    retention: 7d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteMany"]
          resources:
            requests:
              storage: 100Gi

grafana:
  replicas: 2
  deploymentStrategy:
    type: RollingUpdate
```

### Configuración de métricas personalizadas

```yaml
# custom-metrics.yaml
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
    - job_name: 'custom-metrics'
      static_configs:
      - targets: ['custom-app:8080']
      metrics_path: /metrics
      scrape_interval: 15s
```

## Recursos adicionales

- [Repositorio oficial](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Helm Chart](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack)
- [Documentación de Prometheus](https://prometheus.io/docs/)
- [Documentación de Grafana](https://grafana.com/docs/)
- [Guía de configuración](https://medium.com/hedgus/demystifying-kubernetes-monitoring-a-comprehensive-guide-to-prometheus-with-f2468cd20bf1)

## Notas importantes

⚠️ **IMPORTANTE**: Asegúrate de tener suficiente almacenamiento para Prometheus. El valor por defecto de 20Gi puede no ser suficiente para entornos de producción.

⚠️ **IMPORTANTE**: Las credenciales de Grafana están encriptadas con Sealed Secrets. Mantén un backup de las claves de encriptación.

⚠️ **IMPORTANTE**: Para homelabs, considera usar `retention: 1d` para ahorrar espacio de almacenamiento.

⚠️ **IMPORTANTE**: El stack está configurado para usar LoadBalancer. Asegúrate de que MetalLB esté funcionando correctamente.
