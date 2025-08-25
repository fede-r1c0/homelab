# 🌐 Cloudflare Tunnel Setup para K3s

## 🎯 Overview
Configuración de Cloudflare Tunnel usando el **chart oficial de Helm** para exponer servicios del cluster K3s a internet de forma segura.

## 📋 Prerrequisitos
- [x] K3s instalado y funcionando
- [x] Cilium como CNI
- [x] ArgoCD funcionando
- [x] Cuenta de Cloudflare con dominio
- [x] Acceso al cluster K3s

## 🚀 Instalación via Helm Chart

### 1. Crear Tunnel en Cloudflare Dashboard
1. Ir a [Zero Trust > Networks > Tunnels](https://dash.cloudflare.com/zero-trust/networks/tunnels)
2. Click "Create a tunnel"
3. Nombrar: `homelab-k3s`
4. Seleccionar tu dominio
5. **Copiar el Tunnel ID** - lo necesitarás para la configuración

### 2. Configurar Values.yaml
```bash
# Editar el archivo de configuración
nano apps/08-cloudflare-tunnel/values.yaml
```

**Reemplazar estos valores:**
```yaml
tunnel:
  id: "TU_TUNNEL_ID_REAL"  # ← Reemplazar con tu ID
  
ingress:
  # ArgoCD
  - hostname: "argocd.tudominio.com"  # ← Tu dominio real
    service: "http://argocd-server.argocd.svc.cluster.local:80"
  
  # Grafana
  - hostname: "grafana.tudominio.com"  # ← Tu dominio real
    service: "http://prometheus-stack-grafana.monitoring.svc.cluster.local:80"
  
  # Backstage
  - hostname: "backstage.tudominio.com"  # ← Tu dominio real
    service: "http://backstage.backstage.svc.cluster.local:7007"
  
  # Prometheus
  - hostname: "prometheus.tudominio.com"  # ← Tu dominio real
    service: "http://prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
```

### 3. Desplegar via ArgoCD
```bash
# Aplicar la aplicación
kubectl apply -f argocd/applications/08-cloudflare-tunnel.yaml

# Verificar estado
kubectl get applications -n argocd | grep cloudflare
```

### 4. Configurar Autenticación
```bash
# Conectar al pod de cloudflared
kubectl exec -it -n cloudflare-tunnel deployment/cloudflare-tunnel-cloudflared -- cloudflared tunnel login

# Esto abrirá un navegador para autenticarte
# Después de autenticarte, copiar las credenciales
kubectl cp ~/.cloudflared/credentials.json cloudflare-tunnel/cloudflare-tunnel-cloudflared-0:/tmp/credentials.json

# Crear secret con las credenciales
kubectl create secret generic cloudflared-credentials \
  --from-file=credentials.json=/tmp/credentials.json \
  -n cloudflare-tunnel
```

## 🔍 Verificación y Testing

### 1. Verificar Estado del Pod
```bash
# Verificar que el pod esté corriendo
kubectl get pods -n cloudflare-tunnel

# Ver logs del tunnel
kubectl logs -n cloudflare-tunnel -l app.kubernetes.io/name=cloudflare-tunnel-cloudflared -f

# Verificar conectividad
kubectl exec -it -n cloudflare-tunnel deployment/cloudflare-tunnel-cloudflared -- cloudflared tunnel info
```

### 2. Test de Conectividad
```bash
# Desde tu PC local
curl -I https://argocd.tudominio.com
curl -I https://grafana.tudominio.com

# Verificar certificados SSL
openssl s_client -connect argocd.tudominio.com:443 -servername argocd.tudominio.com
```

## 🛠️ Troubleshooting

### Problemas Comunes

#### 1. Tunnel No Conecta
```bash
# Verificar credenciales
kubectl get secret cloudflared-credentials -n cloudflare-tunnel

# Verificar logs
kubectl logs -n cloudflare-tunnel -l app.kubernetes.io/name=cloudflare-tunnel-cloudflared

# Verificar configuración
kubectl describe pod -n cloudflare-tunnel -l app.kubernetes.io/name=cloudflare-tunnel-cloudflared
```

#### 2. Servicios No Accesibles
```bash
# Verificar que los servicios estén corriendo
kubectl get pods -A

# Verificar que los servicios sean accesibles desde el pod de cloudflared
kubectl exec -it -n cloudflare-tunnel deployment/cloudflare-tunnel-cloudflared -- curl http://argocd-server.argocd.svc.cluster.local:80
```

#### 3. Problemas de DNS
```bash
# Verificar resolución DNS
nslookup argocd.tudominio.com

# Verificar configuración en Cloudflare
# Asegurarse de que el dominio apunte a Cloudflare
```

## 🔒 Seguridad

### 1. Network Policies
```yaml
# Crear network policy para restringir tráfico
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cloudflared-network-policy
  namespace: cloudflare-tunnel
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: cloudflare-tunnel-cloudflared
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: argocd
    ports:
    - protocol: TCP
      port: 80
  - to:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 80
```

### 2. RBAC
```yaml
# El chart ya incluye RBAC mínimo necesario
# Solo acceso a secrets y pods en su namespace
```

## 📊 Monitoreo

### 1. Logs del Pod
```bash
# Ver logs en tiempo real
kubectl logs -n cloudflare-tunnel -l app.kubernetes.io/name=cloudflare-tunnel-cloudflared -f

# Ver logs de las últimas 24h
kubectl logs -n cloudflare-tunnel -l app.kubernetes.io/name=cloudflare-tunnel-cloudflared --since="24h"
```

### 2. Métricas del Tunnel
```bash
# Ver estadísticas del tunnel
kubectl exec -it -n cloudflare-tunnel deployment/cloudflare-tunnel-cloudflared -- cloudflared tunnel info

# Ver conexiones activas
kubectl exec -it -n cloudflare-tunnel deployment/cloudflare-tunnel-cloudflared -- cloudflared tunnel info --metrics
```

## 🔄 Actualizaciones

### 1. Actualizar Chart
```bash
# Cambiar versión en values.yaml
# ArgoCD detectará cambios y actualizará automáticamente
```

### 2. Verificar Configuración
```bash
# Test de configuración
kubectl exec -it -n cloudflare-tunnel deployment/cloudflare-tunnel-cloudflared -- cloudflared tunnel --config /etc/cloudflared/config.yml run --loglevel debug
```

## 🎯 Próximos Pasos

1. **Configurar más servicios** según necesites
2. **Implementar autenticación** con Cloudflare Access
3. **Configurar alertas** para caídas del tunnel
4. **Backup de configuración** del tunnel

## 📚 Referencias

- [Cloudflare Community Charts](https://artifacthub.io/packages/helm/community-charts/cloudflared)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [K3s Documentation](https://docs.k3s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

**Nota**: Esta implementación usa el chart oficial de Helm, lo que garantiza compatibilidad y actualizaciones regulares. El tunnel corre como pod en K3s, integrándose perfectamente con tu stack GitOps.
