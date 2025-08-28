# Cloudflared Setup

## ¿Qué es Cloudflared?

Cloudflared es el cliente de Cloudflare Tunnel (anteriormente conocido como Argo Tunnel), un daemon de túnel que actúa como proxy del tráfico desde la red de Cloudflare hacia tus orígenes. Este daemon se sitúa entre la red de Cloudflare y tu origen (por ejemplo, un servidor web), permitiendo que Cloudflare atraiga solicitudes de clientes y las envíe a través de este daemon sin necesidad de abrir agujeros en tu firewall.

### Componentes principales

1. **Tunnel Client**: Cliente que establece la conexión con Cloudflare
2. **Ingress Rules**: Reglas de enrutamiento para diferentes servicios
3. **TLS Termination**: Terminación de TLS en el edge de Cloudflare
4. **Load Balancing**: Balanceo de carga automático
5. **DDoS Protection**: Protección DDoS integrada

### Ventajas principales

- ✅ **Sin agujeros en firewall**: Tu origen puede permanecer completamente cerrado
- ✅ **TLS automático**: Certificados SSL/TLS gestionados por Cloudflare
- ✅ **DDoS protection**: Protección automática contra ataques DDoS
- ✅ **Global CDN**: Distribución global del contenido
- ✅ **Zero Trust**: Acceso seguro sin VPN tradicional

## Instalación

### Configuración en ArgoCD

La aplicación está configurada en ArgoCD con los siguientes parámetros:

```yaml
# argocd/applications/cloudflared.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudflared
  namespace: argocd
  labels:
    project: security
    phase: "5"
    managed-by: argocd
    app.kubernetes.io/name: cloudflared
    app.kubernetes.io/part-of: homelab
spec:
  project: security
  sources:
    - repoURL: https://community-charts.github.io/helm-charts
      chart: cloudflared
      targetRevision: 2.1.2
      helm:
        valueFiles:
          - $values/apps/cloudflared/values.yaml
    - repoURL: https://github.com/fede-r1c0/homelab
      targetRevision: HEAD
      ref: values
      path: apps/cloudflared
      directory:
        include: "cloudflared-sealedsecret.yaml"
  destination:
    server: https://kubernetes.default.svc
    namespace: cloudflared
```

### Configuración de recursos

El archivo `values.yaml` está optimizado para ARM64/Raspberry Pi:

```yaml
# apps/cloudflared/values.yaml
# Despliegue en todos los nodos
replica:
  allNodes: true
  count: 1

# Configuración de secretos del túnel
tunnelSecrets:
  existingPemFileSecret:
    name: "cloudflared-secret"
    key: "cert.pem"
  existingConfigJsonFileSecret:
    name: "cloudflared-secret"
    key: "credentials.json"

# Configuración del túnel
tunnelConfig:
  name: "k3s-homelab"
  protocol: quic
  logLevel: info

# Reglas de ingreso
ingress:
  - hostname: "argocd.feder1c0.tech"
    service: "http://argocd-server.argocd.svc.cluster.local:80"
  - hostname: "grafana.feder1c0.tech"
    service: "http://prometheus-stack-grafana.monitoring.svc.cluster.local:80"
  - hostname: "backstage.feder1c0.tech"
    service: "http://backstage.backstage.svc.cluster.local:7007"
  - service: "http_status:404"

# Recursos optimizados para Raspberry Pi
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"
```

### Configuración de autenticación con Sealed Secrets

Cloudflared utiliza Sealed Secrets para almacenar credenciales sensibles de forma segura:

```yaml
# apps/cloudflared/cloudflared-sealedsecret.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: cloudflared-secret
  namespace: cloudflared
spec:
  encryptedData:
    cert.pem: <certificado-encriptado>
    credentials.json: <credenciales-encriptadas>
  template:
    metadata:
      name: cloudflared-secret
      namespace: cloudflared
    type: Opaque
```

## Configuración del túnel

### Crear un túnel en Cloudflare

1. **Desde el dashboard de Cloudflare**

    - Ve a [dash.cloudflare.com](https://dash.cloudflare.com)
    - Selecciona tu dominio
    - Ve a "Zero Trust" > "Access" > "Tunnels"
    - Click en "Create a tunnel"
    - Nombrar: `k3s-homelab`
    - Seleccionar tu dominio
    - Click en "Create"
    - Copiar el Tunnel ID

2. **Desde la CLI de Cloudflare**

    ```bash
    # Instalar cloudflared localmente
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb sudo dpkg -i cloudflared-linux-arm.deb

    # Autenticarse con Cloudflare
    cloudflared tunnel login

    # Crear un nuevo túnel
    cloudflared tunnel create k3s-homelab

    # Generar regla de routeo de DNS
    cloudflared tunnel route dns k3s-homelab \*.tudominio.com # Reemplazar tudominio.com por tu dominio

    # Copiar el Tunnel ID
    cloudflared tunnel list
    ```

3. **Crear secret encriptado con Sealed Secrets**

Crear un archivo .yaml con el secret encodeado desde los archivos de configuracion de Cloudflare

```bash
kubectl create secret generic cloudflared-secret --from-file=$HOME/.cloudflared/cert.pem --from-file=$HOME/.cloudflared/[Tunnel ID].json --dry-run=client --output=yaml > cloudflared-secret.yaml
```

Encriptar el secret con Sealed Secrets

```bash
kubeseal --controller-name "sealed-secrets" --controller-namespace "sealed-secrets" --format yaml -f cloudflared-secret.yaml -w cloudflared-sealedsecret.yaml
```

Aplicar el secret encriptado a la namespace cloudflared

```bash
kubectl apply -f cloudflared-sealedsecret.yaml
```

Subir secreto encriptado al repositorio

  ```bash
  git add cloudflared-sealedsecret.yaml
  git commit -m "Add cloudflared-sealedsecret.yaml"
  git push
  ```

## Uso básico

### 1. Verificar la instalación

```bash
# Verificar pods de Cloudflared
kubectl get pods -n cloudflared

# Verificar DaemonSet (debe ejecutarse en cada nodo)
kubectl get daemonset -n cloudflared

# Verificar secretos
kubectl get secrets -n cloudflared
```

### 2. Verificar el estado del túnel

```bash
# Ver logs de Cloudflared
kubectl logs -n cloudflared -l app.kubernetes.io/name=cloudflared

# Ver logs en tiempo real
kubectl logs -f -n cloudflared -l app.kubernetes.io/name=cloudflared

```

### 3. Probar la conectividad

```bash
# Probar acceso a ArgoCD
curl -I https://argocd.feder1c0.tech

# Probar acceso a Grafana
curl -I https://grafana.feder1c0.tech

# Probar acceso a Backstage
curl -I https://backstage.feder1c0.tech
```

## Configuración de DNS

### Configurar registros DNS

Es posible configurar el routeo de DNS desde la CLI de Cloudflare con el siguiente comando:

```bash
cloudflared tunnel route dns k3s-homelab \*.tudominio.com # Reemplazar tudominio.com por tu dominio
```

Sino, puedes hacerlo desde el dashboard de Cloudflare, por ejemplo:

```yaml
# Registros DNS en Cloudflare
argocd.feder1c0.tech    CNAME    k3s-homelab.tudominio.com
grafana.feder1c0.tech   CNAME    k3s-homelab.tudominio.com
backstage.feder1c0.tech CNAME    k3s-homelab.tudominio.com
```

### Configuración de proxy

- **Proxy status**: Proxied (naranja)
- **SSL/TLS**: Full (strict)
- **Always Use HTTPS**: On
- **HSTS**: Enabled

## Configuración avanzada

### Configuración de múltiples túneles

```yaml
# multiple-tunnels.yaml
tunnelConfig:
  - name: "k3s-homelab"
    protocol: quic
    logLevel: info
  - name: "k3s-backup"
    protocol: http2
    logLevel: warn

ingress:
  - hostname: "*.feder1c0.tech"
    service: "http://argocd-server.argocd.svc.cluster.local:80"
  - hostname: "api.feder1c0.tech"
    service: "http://api-server.api.svc.cluster.local:8080"
```

### Configuración de load balancing

```yaml
# load-balancing.yaml
ingress:
  - hostname: "app.feder1c0.tech"
    service: "http://app-1.app.svc.cluster.local:80"
    originRequest:
      loadBalancer:
        policy: random
  - hostname: "app.feder1c0.tech"
    service: "http://app-2.app.svc.cluster.local:80"
    originRequest:
      loadBalancer:
        policy: random
```

### Configuración de seguridad

```yaml
# security-config.yaml
ingress:
  - hostname: "admin.feder1c0.tech"
    service: "http://admin-panel.admin.svc.cluster.local:80"
    originRequest:
      access:
        required: true
        teamName: "homelab"
        audTag: ["admin"]
```

## Comandos útiles

### Verificar el estado del túnel

```bash
# Ver información del túnel
kubectl exec -n cloudflared deployment/cloudflared -- cloudflared tunnel info k3s-homelab

# Ver lista de túneles
kubectl exec -n cloudflared deployment/cloudflared -- cloudflared tunnel list

# Ver logs del túnel
kubectl exec -n cloudflared deployment/cloudflared -- cloudflared tunnel logs k3s-homelab
```

### Gestión de secretos

```bash
# Ver secretos encriptados
kubectl get sealedsecrets -n cloudflared

# Ver secretos desencriptados
kubectl get secrets -n cloudflared

# Ver contenido de credenciales
kubectl get secret cloudflared-secret -n cloudflared -o jsonpath='{.data.credentials\.json}' | base64 -d
```

### Debugging y troubleshooting

```bash
# Ver logs de Cloudflared en tiempo real
kubectl logs -f -n cloudflared -l app.kubernetes.io/name=cloudflared

# Ver eventos del namespace
kubectl get events -n cloudflared --sort-by='.lastTimestamp'
```

## Mejores prácticas

### 1. **Configuración de recursos**

- Ajusta límites de memoria y CPU según el hardware disponible
- Monitorea el uso de recursos de Cloudflared
- Usa DaemonSet para alta disponibilidad

### 2. **Seguridad**

- Usa Sealed Secrets para todas las credenciales sensibles
- Implementa políticas de acceso Zero Trust
- Limita el acceso a servicios internos

### 3. **Red y conectividad**

- Usa protocolo QUIC para mejor rendimiento
- Configura timeouts apropiados
- Monitorea la latencia del túnel

### 4. **Monitoreo**

- Configura alertas para fallos del túnel
- Monitorea el estado de conectividad
- Revisa logs regularmente para detectar problemas

## Troubleshooting

### Problema: Túnel no se conecta

```bash
# Verificar credenciales
kubectl get secret cloudflared-secret -n cloudflared -o yaml

# Verificar logs de conexión
kubectl logs -n cloudflared -l app.kubernetes.io/name=cloudflared | grep -i error

# Verificar configuración del túnel
kubectl exec -n cloudflared deployment/cloudflared -- cloudflared tunnel info k3s-homelab
```

### Problema: Servicios no son accesibles

```bash
# Verificar reglas de ingress
kubectl get configmap -n cloudflared cloudflared-config -o yaml

# Verificar conectividad interna
kubectl exec -n cloudflared deployment/cloudflared -- curl argocd-server.argocd.svc.cluster.local:80

# Verificar DNS interno
kubectl exec -n cloudflared deployment/cloudflared -- nslookup argocd-server.argocd.svc.cluster.local
```

### Problema: Certificados SSL expirados

```bash
# Verificar estado del certificado
kubectl exec -n cloudflared deployment/cloudflared -- cloudflared tunnel info k3s-homelab

# Regenerar credenciales del túnel
cloudflared tunnel token k3s-homelab

# Aplicar nuevas credenciales
kubectl apply -f cloudflared-sealedsecret.yaml
```

### Problema: Alto uso de recursos

```bash
# Verificar uso de recursos
kubectl top pods -n cloudflared

# Ajustar límites en values.yaml
# Reducir logLevel si es necesario
```

## Configuración de monitoreo

### ServiceMonitor para Prometheus

```yaml
# cloudflared-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cloudflared
  namespace: monitoring
  labels:
    release: prometheus-stack
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: cloudflared
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Métricas personalizadas

```yaml
# custom-metrics.yaml
tunnelConfig:
  metrics: 0.0.0.0:9090
  metrics-port: 9090
  logLevel: info
```

## Recursos adicionales

- [Repositorio oficial](https://github.com/cloudflare/cloudflared)
- [Documentación oficial de Kubernetes](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deployment-guides/kubernetes/)
- [Helm Chart de la comunidad](https://artifacthub.io/packages/helm/community-charts/cloudflared)
- [Guía de túneles](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/)
- [Configuración de ingress](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/configuration-file/)

## Notas importantes

⚠️ **IMPORTANTE**: Las credenciales del túnel están encriptadas con Sealed Secrets. Mantén un backup de las claves de encriptación.

⚠️ **IMPORTANTE**: Cloudflared está configurado como DaemonSet para ejecutarse en todos los nodos. Asegúrate de que todos los nodos tengan acceso a internet.

⚠️ **IMPORTANTE**: Los certificados del túnel tienen una validez limitada. Configura renovación automática o monitoreo de expiración.

⚠️ **IMPORTANTE**: El túnel expone servicios internos a internet. Implementa políticas de acceso apropiadas en Cloudflare Zero Trust.
