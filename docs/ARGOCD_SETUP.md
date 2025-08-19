# ArgoCD Setup y Configuración GitOps

Esta guía te ayuda a configurar ArgoCD en tu cluster k3s para implementar un flujo GitOps completo. Vamos a usar el patrón "App of Apps" para gestionar todo el ecosistema de aplicaciones desde un solo punto de entrada.

## 🚀 Instalación de ArgoCD

### **Prerequisitos**

- Cluster `k3s` funcionando con `Cilium` como CNI
- `kubectl` configurado y conectado al cluster
- `helm` instalado

### **1. Instalación con Helm Chart Oficial**

Desde tu Raspberry Pi (conectado via SSH), ejecutá estos comandos:

```bash
# Agregar repositorio oficial de ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Instalar ArgoCD con configuración estándar
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set configs.params."server\.insecure"=true

# Verificar que se instaló correctamente
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### **2. Acceso Inicial**

Por defecto, ArgoCD se instala con un servicio ClusterIP. Para acceder inicialmente:

```bash
# Port-forward para acceso local
kubectl port-forward svc/argocd-server -n argocd 8080:80 &

# Obtener password inicial
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d

# Acceder via: http://localhost:8080
# Usuario: admin
# Password: [resultado del comando anterior]
```

**Nota:** Más adelante, cuando instales MetalLB, podrás cambiar el servicio a LoadBalancer para acceso directo desde tu red.

## 🏗️ Arquitectura del Repositorio

### **Estructura Implementada**

```bash
homelab/
├── argocd/                      # Configuración de ArgoCD
│   ├── projects/                # Proyectos con RBAC granular
│   │   ├── bootstrap.yaml       # Apps base del cluster
│   │   ├── security.yaml        # Apps de seguridad
│   │   ├── monitoring.yaml      # Stack de observabilidad
│   │   └── applications.yaml    # Apps de nivel aplicación
│   └── applications/            # Definiciones de aplicaciones
│       ├── homelab-bootstrap.yaml
│       ├── 00-sealed-secrets.yaml
│       ├── 01-metallb.yaml
│       └── [otras apps...]
├── apps/                        # Valores personalizados para cada app
│   ├── 00-sealed-secrets/values.yaml
│   ├── 01-metallb/values.yaml
│   └── [otras configuraciones...]
```

### **Cómo Funciona la Arquitectura**

#### **🎯 Patrón "App of Apps"**

- **`homelab-bootstrap`**: App principal que lee `argocd/applications/`
- **Apps individuales**: Cada definición en `applications/` crea una app específica
- **Helm charts oficiales**: Cada app usa su chart oficial + valores custom
- **Sincronización automática**: Cambios en Git se aplican automáticamente

#### **🔒 Proyectos para RBAC**

- **bootstrap**: Apps críticas (Sealed Secrets, MetalLB, cert-manager)
- **security**: Herramientas de seguridad (OPA Gatekeeper)
- **monitoring**: Stack de observabilidad (Prometheus, Grafana, Loki)
- **applications**: Apps de nivel usuario (Backstage)

#### **📦 Sistema de Dependencias**

```text
Sealed Secrets (00) → Base para secretos
     ↓
MetalLB (01) → LoadBalancer para servicios
     ↓
cert-manager (02) → Certificados TLS
     ↓
OPA Gatekeeper (03) → Políticas de seguridad
     ↓
Prometheus Stack (04) → Observabilidad
     ↓
Backstage (05) → Developer Portal
```

## 🛠️ Configuración Manual de GitOps

### **1. Crear Proyectos ArgoCD**

Primero, creá los proyectos que van a organizar tus aplicaciones:

```bash
# Aplicar proyectos con RBAC
kubectl apply -f argocd/projects/

# Verificar que se crearon
kubectl get appprojects -n argocd
```

### **2. Agregar Repositorio GitHub**

```bash
# Login a ArgoCD CLI
argocd login localhost:8080 --username admin --password [PASSWORD] --insecure

# Agregar tu repositorio
argocd repo add $REPO_URL --insecure

# Verificar que se agregó
argocd repo list
```

### **3. Crear Aplicación Bootstrap**

```bash
# Crear la app principal que gestiona todo
kubectl apply -f argocd/applications/homelab-bootstrap.yaml

# Verificar que se creó
argocd app get homelab-bootstrap

# Sincronizar para que empiece a crear las otras apps
argocd app sync homelab-bootstrap
```

### **4. Monitorear el Despliegue**

```bash
# Ver todas las aplicaciones
argocd app list

# Ver estado detallado de una app
argocd app get sealed-secrets

# Ver logs de sincronización
argocd app logs sealed-secrets --follow
```

## 🔧 Configuración Específica por Aplicación

### **Sealed Secrets (00-sealed-secrets)**

```yaml
# Se instala automáticamente, no requiere configuración manual
# Usa el chart oficial de Bitnami con recursos optimizados para Raspberry Pi
```

### **MetalLB (01-metallb)**

**⚠️ Configuración Crítica:** MetalLB necesita un pool de IPs configurado.

```bash
# Después de que se instale MetalLB, verificar que necesita configuración
kubectl get ipaddresspools -n metallb-system

# Si está vacío, MetalLB está instalado pero sin configurar
# La configuración está en apps/01-metallb/values.yaml:
# ipAddressPools:
#   - name: default
#     addresses:
#       - 192.168.68.100-192.168.68.105
```

**Cambiar ArgoCD a LoadBalancer:**

```bash
# Una vez que MetalLB esté configurado y funcionando
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# Verificar que obtiene IP externa (debería ser una IP del pool 192.168.68.100-105)
kubectl get svc argocd-server -n argocd -w

# Ejemplo de resultado esperado:
# NAME            TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
# argocd-server   LoadBalancer   10.43.181.160   192.168.68.100   80:31766/TCP,443:31617/TCP
```

### **cert-manager (02-cert-manager)**

```bash
# Verificar que los CRDs se instalaron correctamente
kubectl get crd | grep cert-manager

# Verificar que los webhooks están funcionando
kubectl get validatingwebhookconfigurations | grep cert-manager
```

### **Prometheus Stack (04-prometheus-stack)**

**⚠️ Aplicación Pesada:** Requiere más recursos y tiempo de instalación.

```bash
# Monitorear la instalación (puede tardar varios minutos)
kubectl get pods -n monitoring -w

# Verificar que Grafana está funcionando
kubectl get svc -n monitoring | grep grafana

# Acceder a Grafana (una vez que MetalLB esté configurado)
# URL: http://[METALLB-IP]:3000
# Usuario: admin / Contraseña: prom-operator
```

### **OPA Gatekeeper (03-opa-gatekeeper)**

```bash
# Verificar que los admission controllers están activos
kubectl get validatingwebhookconfigurations | grep gatekeeper

# Ver qué políticas están aplicadas
kubectl get constrainttemplate
```

## 📊 Verificación del Estado General

### **Comandos Útiles**

```bash
# Estado de todas las aplicaciones ArgoCD
argocd app list

# Apps que no están sincronizadas
argocd app list | grep -v Synced

# Ver recursos de todos los namespaces
kubectl get pods --all-namespaces

# Ver servicios con IPs externas
kubectl get svc --all-namespaces | grep LoadBalancer
```

### **Troubleshooting Común**

1. **App en estado OutOfSync**

   ```bash
   # Forzar sincronización
   argocd app sync [APP-NAME] --force

   # Ver logs detallados
   argocd app logs [APP-NAME]
   ```

2. **MetalLB no asigna IPs**

   ```bash
   # Verificar configuración de pools
   kubectl get ipaddresspools -n metallb-system -o yaml

   # Ver logs de MetalLB
   kubectl logs -n metallb-system -l app=metallb
   ```

3. **Pods en Pending**

   ```bash
   # Verificar recursos del nodo
   kubectl describe node [NODE-NAME]

   # Ver eventos del cluster
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

## ⚡ Script de Automatización

Para los que prefieren automatizar todo el proceso, hay un script disponible:

```bash
# Ejecutar bootstrap automático
./scripts/bootstrap-argocd.sh
```

**Nota:** El script automatiza todo lo explicado arriba, pero es recomendable entender el proceso manual primero. En versiones futuras se mejorarán los scripts para mayor confiabilidad.

## 🎯 Próximos Pasos

Una vez que tengas todo funcionando:

1. **Configurar alertas** en Prometheus
2. **Agregar políticas** personalizadas en OPA Gatekeeper
3. **Configurar Backstage** como developer portal
4. **Implementar backup** con Velero
5. **Experimentar** con más aplicaciones

## 📚 Recursos Adicionales

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [MetalLB Configuration](https://metallb.universe.tf/configuration/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
