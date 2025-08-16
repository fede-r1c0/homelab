# ArgoCD Setup y Configuración GitOps

## 🏗️ Arquitectura Implementada

### **Estructura del Repositorio (Versión Final)**
```
homelab/
├── .github/workflows/           # Validación automática de manifiestos
├── argocd/                      # Configuración de ArgoCD
│   ├── projects/                # Definición de proyectos con RBAC
│   ├── applications/            # Aplicaciones individuales (App of Apps)
│   └── application-sets/        # ApplicationSets para gestión masiva
├── apps/                        # Configuraciones de aplicaciones (values.yaml)
│   ├── 00-sealed-secrets/      # Gestión de secretos
│   ├── 01-metallb/             # Load balancer
│   ├── 02-cert-manager/        # Certificados TLS
│   ├── 03-opa-gatekeeper/      # Políticas de seguridad
│   ├── 04-prometheus-stack/    # Stack de observabilidad
│   │   ├── kube-prometheus-stack/
│   │   ├── loki/
│   │   └── tempo/
│   └── 05-backstage/           # Developer Portal
├── policies/                    # Políticas OPA para validación
└── docs/                        # Documentación técnica
```

### **Sistema de Dependencias (Versión Final)**
Las aplicaciones se instalan en orden secuencial para respetar las dependencias:

1. **00-sealed-secrets** → No depende de nada
2. **01-metallb** → No depende de nada
3. **02-cert-manager** → Depende de MetalLB para LoadBalancer
4. **03-opa-gatekeeper** → Depende de cert-manager para webhooks TLS
5. **04-prometheus-stack** → Depende de cert-manager para certificados
6. **05-backstage** → Depende del stack de monitoreo

### **Patrón App of Apps Implementado**
- **`homelab-bootstrap`**: Aplicación principal que gestiona todo el ecosistema
- **Aplicaciones individuales**: Cada herramienta tiene su configuración específica
- **Proyectos separados**: RBAC granular por categoría de aplicación
- **Auto-discovery**: ArgoCD lee automáticamente desde el repositorio

## 🚀 **Instalación y Configuración**

### **1. Configurar Repositorio en ArgoCD (Recomendado)**
```bash
# En ArgoCD UI: Settings > Repositories > Connect Repo
Repository URL: https://github.com/fede-r1c0/homelab
Type: Git
```

### **2. Crear Aplicación Bootstrap en ArgoCD UI**
```bash
# En ArgoCD UI: Applications > New App
Application Name: homelab-bootstrap
Project: default
Repository URL: https://github.com/fede-r1c0/homelab
Revision: HEAD
Path: argocd
```

### **3. ArgoCD Auto-Descubre Todo**
Una vez creada la aplicación bootstrap, ArgoCD automáticamente:
- ✅ Lee `argocd/projects/` → Crea los proyectos
- ✅ Lee `argocd/applications/` → Crea las aplicaciones
- ✅ Cada aplicación instala su Helm chart + values.yaml
- ✅ Todo se sincroniza automáticamente

### **4. Monitorear el Despliegue**
```bash
# Ver estado de sincronización
argocd app list

# Ver logs de una aplicación específica
argocd app logs sealed-secrets

# Ver estado detallado
argocd app get sealed-secrets
```

## 🔧 **Configuración de Aplicaciones**

### **Sealed Secrets (00-sealed-secrets)**
- **Chart**: `bitnami/sealed-secrets`
- **Versión**: `2.8.0`
- **Configuración**: Optimizada para Raspberry Pi con recursos limitados
- **Funcionalidad**: Encripta secretos antes de almacenarlos en Git
- **Source**: Chart oficial + `apps/00-sealed-secrets/values.yaml`

### **MetalLB (01-metallb)**
- **Chart**: `metallb/metallb`
- **Versión**: `0.13.12`
- **Configuración**: Single-node cluster, recursos optimizados
- **Funcionalidad**: Proporciona LoadBalancer para servicios
- **Source**: Chart oficial + `apps/01-metallb/values.yaml`

### **cert-manager (02-cert-manager)**
- **Chart**: `jetstack/cert-manager`
- **Versión**: `v1.13.3`
- **Configuración**: Webhooks habilitados, recursos optimizados
- **Funcionalidad**: Gestión automática de certificados TLS
- **Source**: Chart oficial + `apps/02-cert-manager/values.yaml`

## 📊 **Monitoreo y Observabilidad**

### **Prometheus Stack (04-prometheus-stack)**
- **kube-prometheus-stack**: Prometheus + Grafana + AlertManager
  - **Chart**: `prometheus-community/kube-prometheus-stack`
  - **Versión**: `55.5.0`
  - **Source**: Chart oficial + `apps/04-prometheus-stack/kube-prometheus-stack/values.yaml`
- **Loki**: Agregación de logs
  - **Chart**: `grafana/loki`
  - **Versión**: `5.41.3`
  - **Source**: Chart oficial + `apps/04-prometheus-stack/loki/values.yaml`
- **Tempo**: Distributed tracing
  - **Chart**: `grafana/tempo`
  - **Versión**: `1.5.0`
  - **Source**: Chart oficial + `apps/04-prometheus-stack/tempo/values.yaml`

### **Configuración de Recursos**
Todas las aplicaciones están configuradas con:
- **Resource limits** optimizados para Raspberry Pi
- **Security contexts** apropiados (no root)
- **High availability** deshabilitada para single-node
- **Automated sync** con rollback automático

## 🔒 **Seguridad y Compliance**

### **OPA Gatekeeper (03-opa-gatekeeper)**
- **Chart**: `open-policy-agent/gatekeeper`
- **Versión**: `3.12.0`
- **Políticas**: Valida recursos antes de su creación
- **Configuración**: Webhooks TLS, recursos optimizados
- **Funcionalidad**: Policy enforcement en tiempo real
- **Source**: Chart oficial + `apps/03-opa-gatekeeper/values.yaml`

### **Políticas Implementadas**
- **ArgoCD**: Validación de Applications y Projects
- **Kubernetes**: Seguridad de pods, recursos, networking
- **Secrets**: Gestión segura con Sealed Secrets

## 🚨 **Rollback Automático**

### **Configuración de Rollback**
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  retry:
    limit: 2
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

### **Comportamiento**
- **Reintentos**: Máximo 2 reintentos en caso de fallo
- **Backoff exponencial**: 5s → 10s → 20s
- **Rollback automático**: Después de 2 fallos consecutivos
- **Self-healing**: ArgoCD intenta recuperar automáticamente

## 🔍 **Validación y Testing**

### **GitHub Actions**
- **Trigger**: En cada PR y push a main/develop
- **Validaciones**:
  - Sintaxis YAML con `yamllint`
  - Políticas OPA con `conftest`
  - Validación de esquemas Kubernetes
  - Verificación de ArgoCD Applications

### **Políticas OPA**
- **argocd.rego**: Valida Applications y Projects
- **apps.rego**: Valida recursos Kubernetes
- **Validaciones**: Labels, security contexts, resource limits

## 📋 **Comandos Útiles**

### **Gestión de Aplicaciones**
```bash
# Listar todas las aplicaciones
argocd app list

# Sincronizar una aplicación
argocd app sync sealed-secrets

# Ver estado de sincronización
argocd app get sealed-secrets

# Ver logs de sincronización
argocd app logs sealed-secrets

# Rollback a versión anterior
argocd app rollback sealed-secrets
```

### **Monitoreo del Cluster**
```bash
# Estado general del cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Estado de ArgoCD
kubectl get pods -n argocd
kubectl get svc -n argocd

# Logs de ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

## 🚨 **Troubleshooting**

### **Problemas Comunes**

1. **Aplicación en estado OutOfSync**
   ```bash
   # Verificar conectividad con repositorio
   argocd app get <app-name>
   
   # Forzar sincronización
   argocd app sync <app-name>
   ```

2. **Pods en estado Pending**
   ```bash
   # Verificar recursos del nodo
   kubectl describe node <node-name>
   
   # Verificar eventos
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

3. **Webhooks fallando**
   ```bash
   # Verificar certificados de cert-manager
   kubectl get certificates -n cert-manager
   
   # Verificar webhook configurations
   kubectl get validatingwebhookconfigurations
   ```

### **Logs de Diagnóstico**
```bash
# Logs de ArgoCD Application Controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Logs de ArgoCD Server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Logs de ArgoCD Repo Server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

## 🔄 **Mantenimiento y Actualizaciones**

### **Actualización de Charts**
```bash
# Actualizar versión de un chart
helm repo update
helm search repo <chart-name>

# Modificar values.yaml y hacer commit
git add apps/<app-name>/values.yaml
git commit -m "Update <app-name> to version X.Y.Z"
git push
```

### **Backup de Configuraciones**
```bash
# Exportar configuración de ArgoCD
kubectl get applications -n argocd -o yaml > argocd-backup.yaml
kubectl get appprojects -n argocd -o yaml > projects-backup.yaml
```

## 📚 **Recursos Adicionales**

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [MetalLB](https://metallb.universe.tf/)
- [cert-manager](https://cert-manager.io/)

## 🤝 **Soporte**

Para problemas específicos o mejoras:
1. Revisar logs y eventos del cluster
2. Verificar estado de sincronización en ArgoCD UI
3. Consultar documentación oficial de cada herramienta
4. Crear issue en el repositorio con logs y contexto
