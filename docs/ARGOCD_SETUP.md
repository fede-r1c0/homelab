# 🚀 ArgoCD Setup para Homelab

## 🎯 Overview
Configuración de ArgoCD usando el **chart oficial de Helm** para implementar GitOps en tu cluster K3s.

## 📋 Prerrequisitos
- [x] K3s instalado y funcionando
- [x] Cilium como CNI
- [x] Helm configurado
- [x] Acceso al cluster K3s

## 🚀 Instalación via Helm Chart Oficial

### 1. Agregar Repositorio de Helm
```bash
# Agregar repositorio oficial de ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### 2. Configurar Values.yaml
```bash
# Editar la configuración
nano apps/00-argocd/values.yaml
```

### 3. Instalar ArgoCD via Helm
```bash
# Instalar ArgoCD con configuración personalizada
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values apps/00-argocd/values.yaml \
  --wait
```

### 4. Verificar Instalación
```bash
# Verificar pods
kubectl get pods -n argocd

# Verificar servicios
kubectl get svc -n argocd

# Verificar aplicaciones
kubectl get applications -n argocd
```

### 5. Obtener Contraseña de Admin
```bash
# Obtener contraseña inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 6. Acceder a ArgoCD
```bash
# Port-forward para acceso local
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Abrir navegador en http://localhost:8080
# Usuario: admin
# Contraseña: [obtenida en paso 5]
```

## 🔧 Configuración Avanzada

### Configuración de Ingress
```yaml
# En values.yaml
server:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - argocd.yourdomain.com
    tls:
      - secretName: argocd-tls
        hosts:
          - argocd.yourdomain.com
```

### Configuración de Recursos
```yaml
# Optimizado para Raspberry Pi
server:
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

### Configuración de Seguridad
```yaml
# Para desarrollo/homelab
server:
  extraArgs:
    - --insecure
    - --disable-auth
    - --disable-auth-override
```

## 🔍 Verificación y Testing

### 1. Verificar Estado del Cluster
```bash
# Verificar todos los componentes
kubectl get all -n argocd

# Verificar logs del servidor
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Verificar logs del repositorio
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server -f
```

### 2. Test de Conectividad
```bash
# Test de conexión al servidor
kubectl exec -it -n argocd deployment/argocd-server -- curl http://localhost:8080/healthz

# Test de conexión al repositorio
kubectl exec -it -n argocd deployment/argocd-repo-server -- curl http://localhost:8081/healthz
```

### 3. Verificar Aplicaciones
```bash
# Ver aplicaciones desplegadas
argocd app list

# Ver estado de sincronización
argocd app get homelab-bootstrap
```

## 🛠️ Troubleshooting

### Problemas Comunes

#### 1. Pods No Arrancan
```bash
# Verificar eventos
kubectl get events -n argocd --sort-by=.metadata.creationTimestamp

# Verificar logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Verificar recursos
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-server
```

#### 2. Problemas de Conectividad
```bash
# Verificar servicios
kubectl get svc -n argocd

# Verificar endpoints
kubectl get endpoints -n argocd

# Test de conectividad interna
kubectl exec -it -n argocd deployment/argocd-server -- curl http://argocd-repo-server:8081
```

#### 3. Problemas de Autenticación
```bash
# Verificar secret de admin
kubectl get secret -n argocd argocd-initial-admin-secret

# Resetear contraseña si es necesario
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData":{"admin.password":"nueva-contraseña"}}'
```

## 🔒 Seguridad

### 1. Configuración de RBAC
```yaml
# En values.yaml
rbac:
  create: true
  pspEnabled: false
```

### 2. Network Policies
```yaml
# Crear network policy para ArgoCD
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-network-policy
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []
  egress:
  - to: []
```

## 📊 Monitoreo

### 1. Métricas de Prometheus
```yaml
# En values.yaml
metrics:
  enabled: true
  service:
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "8080"
```

### 2. Logs del Sistema
```bash
# Ver logs en tiempo real
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Ver logs de las últimas 24h
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --since="24h"
```

## 🔄 Actualizaciones

### 1. Actualizar Chart
```bash
# Actualizar repositorio
helm repo update

# Actualizar ArgoCD
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --values apps/00-argocd/values.yaml
```

### 2. Verificar Configuración
```bash
# Verificar configuración actual
helm get values argocd -n argocd

# Verificar estado del deployment
kubectl get deployment argocd-server -n argocd
```

## 🎯 Próximos Pasos

1. **Configurar repositorio de GitHub** en values.yaml
2. **Crear aplicación bootstrap** para auto-desplegar el resto
3. **Configurar ingress** para acceso externo
4. **Implementar políticas de seguridad** con RBAC

## 📚 Referencias

- [ArgoCD Helm Chart](https://artifacthub.io/packages/helm/argo/argo-cd)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [K3s Documentation](https://docs.k3s.io/)

---

**Nota**: Esta implementación usa solo el chart oficial de Helm, sin scripts de bash. Todo se configura a través de values.yaml y se despliega directamente con Helm.
