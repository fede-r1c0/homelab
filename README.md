# HomeLab - Kubernetes en Raspberry Pi 5

## 📋 Descripción

Laboratorio local de Kubernetes hosteado en Raspberry Pi 5 para experimentación y desarrollo. Este proyecto implementa un stack completo de herramientas de observabilidad, seguridad y GitOps utilizando K3S como distribución de Kubernetes.

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Raspberry Pi 5                       │
│  ┌─────────────────────────────────────────────────────┐ │
│  │               Ubuntu Server 25.04                   │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │                   K3S                           │ │ │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │ │ │
│  │  │  │ Observabilidad│  │  Seguridad  │  │ GitOps   │ │ │ │
│  │  │  │  - Prometheus │  │ - OPA GK    │  │ - ArgoCD │ │ │ │
│  │  │  │  - Grafana    │  │ - Falco     │  │          │ │ │ │
│  │  │  │  - Loki       │  │             │  │          │ │ │ │
│  │  │  │  - Tempo      │  │             │  │          │ │ │ │
│  │  │  │  - OpenTel    │  │             │  │          │ │ │ │
│  │  │  └─────────────┘  └─────────────┘  └──────────┘ │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Stack de Tecnologías

### Core Infrastructure
- **OS**: Ubuntu Server 25.04
- **Kubernetes**: K3S (ligero y optimizado para ARM64)
- **CNI**: Cilium (networking avanzado y eBPF)
- **Load Balancer**: MetalLB
- **Certificate Management**: cert-manager

### Observabilidad y Monitoreo
- **Métricas**: Prometheus
- **Visualización**: Grafana
- **Logs**: Loki
- **Tracing**: Tempo
- **Instrumentación**: OpenTelemetry

### DevOps y Seguridad
- **GitOps**: ArgoCD
- **Developer Portal**: Backstage
- **Policy Engine**: OPA Gatekeeper
- **Runtime Security**: Falco

## 📦 Prerrequisitos

- Raspberry Pi 5 (4GB+ RAM recomendado)
- MicroSD Card (32GB+ clase 10)
- Conexión a Internet estable
- PC con SSH client
- Repositorio GitHub con manifiestos y configuraciones Helm

## 🛠️ Instalación

### 1. Preparación del Sistema Base

```bash
# Flash Ubuntu Server 25.04 en la microSD
# Configuración inicial tras el primer boot
sudo apt update && sudo apt upgrade -y

# Instalación de paquetes esenciales
sudo apt install -y curl wget git vim htop tree jq unzip
```

### 2. Configuración SSH

```bash
# Generar clave SSH para GitHub
ssh-keygen -t ed25519 -C "your-email@example.com"

# Configurar SSH server
sudo systemctl enable ssh
sudo systemctl start ssh

# Agregar clave pública a GitHub
cat ~/.ssh/id_ed25519.pub
```

### 3. Configuración del Entorno de Desarrollo

```bash
# Clonar dotfiles
git clone git@github.com:username/dotfiles.git ~/dotfiles

# Instalar GNU Stow
sudo apt install -y stow

# Aplicar configuraciones
cd ~/dotfiles
stow .
```

### 4. Instalación de K3S

```bash
# Instalar K3S sin Traefik (usaremos Cilium)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none --disable-network-policy --disable=traefik" sh -

# Configurar kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### 5. Instalación de Cilium CNI

```bash
# Instalar Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-arm64.tar.gz
sudo tar xzvfC cilium-linux-arm64.tar.gz /usr/local/bin

# Instalar Cilium en el cluster
cilium install
cilium status --wait
```

### 6. Instalación de ArgoCD (Bootstrap GitOps)

```bash
# Crear namespace y aplicar manifiestos
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Exponer ArgoCD UI
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Obtener contraseña inicial de ArgoCD
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 7. Configuración GitOps - App of Apps Pattern

```bash
# Configurar repositorio principal en ArgoCD
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
	name: homelab-apps
	namespace: argocd
spec:
	project: default
	source:
		repoURL: https://github.com/username/homelab
		targetRevision: HEAD
		path: apps
	destination:
		server: https://kubernetes.default.svc
		namespace: argocd
	syncPolicy:
		automated:
			prune: true
			selfHeal: true
EOF
```

## 🗂️ Estructura del Repositorio GitOps

```
homelab/
├── apps/
│   ├── metallb/
│   │   ├── application.yaml
│   │   └── values.yaml
│   ├── cert-manager/
│   │   ├── application.yaml
│   │   └── values.yaml
│   ├── monitoring/
│   │   ├── prometheus/
│   │   │   ├── application.yaml
│   │   │   └── values.yaml
│   │   ├── grafana/
│   │   │   ├── application.yaml
│   │   │   └── values.yaml
│   │   ├── loki/
│   │   │   ├── application.yaml
│   │   │   └── values.yaml
│   │   └── tempo/
│   │       ├── application.yaml
│   │       └── values.yaml
│   ├── security/
│   │   ├── gatekeeper/
│   │   │   ├── application.yaml
│   │   │   └── values.yaml
│   │   └── falco/
│   │       ├── application.yaml
│   │       └── values.yaml
│   └── backstage/
│       ├── application.yaml
│       └── values.yaml
└── README.md
```

## 📋 Despliegue de Aplicaciones via GitOps

### MetalLB
```yaml
# apps/metallb/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
	name: metallb
	namespace: argocd
spec:
	project: default
	source:
		repoURL: https://metallb.github.io/metallb
		chart: metallb
		targetRevision: 0.13.12
		helm:
			valueFiles:
			- values.yaml
	destination:
		server: https://kubernetes.default.svc
		namespace: metallb-system
	syncPolicy:
		automated:
			prune: true
			selfHeal: true
		syncOptions:
		- CreateNamespace=true
```

### Stack de Observabilidad
Las herramientas de monitoreo se despliegan utilizando ArgoCD con charts oficiales de Helm:

- **Prometheus**: `prometheus-community/kube-prometheus-stack`
- **Grafana**: Incluido en kube-prometheus-stack
- **Loki**: `grafana/loki-stack`
- **Tempo**: `grafana/tempo`

Cada aplicación utiliza su respectivo `values.yaml` personalizado para configurar:
- Recursos optimizados para Raspberry Pi
- Configuración de LoadBalancer services
- Dashboards predeterminados
- Alerting rules

### Herramientas de Seguridad
- **OPA Gatekeeper**: Utilizando manifiestos oficiales con políticas personalizadas
- **Falco**: Chart oficial `falcosecurity/falco` con configuración ARM64

## 🔍 Verificación de la Instalación

```bash
# Verificar estado del cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Verificar ArgoCD Applications
kubectl get applications -n argocd

# Estado de sincronización GitOps
argocd app list
argocd app sync homelab-apps

# Verificar servicios expuestos
kubectl get svc --all-namespaces | grep LoadBalancer

# Estado de Cilium
cilium status
```

## 📊 Acceso a Servicios

| Servicio | Puerto | URL | Credenciales |
|----------|--------|-----|--------------|
| ArgoCD | 80 | http://cluster-ip | admin/[kubectl get secret] |
| Grafana | 80 | http://cluster-ip | admin/prom-operator |
| Prometheus | 9090 | http://cluster-ip:9090 | - |
| Backstage | 7007 | http://cluster-ip:7007 | - |

## 🔧 Troubleshooting

### Problemas Comunes

1. **ArgoCD Applications en OutOfSync**: Verificar conectividad con repositorio GitHub
2. **Pods en estado Pending**: Revisar recursos y taints del nodo
3. **Servicios LoadBalancer en Pending**: Verificar configuración de MetalLB
4. **GitOps sync failures**: Revisar logs de ArgoCD y validar manifiestos

### Comandos de Diagnóstico

```bash
# Estado de ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
argocd app get homelab-apps

# Estado general del cluster
kubectl cluster-info
kubectl get events --sort-by=.metadata.creationTimestamp

# Recursos del sistema
free -h
df -h
systemctl status k3s
```

## 🔄 Flujo de Trabajo GitOps

1. **Modificar configuraciones**: Editar `values.yaml` en el repositorio
2. **Commit y Push**: Subir cambios a GitHub
3. **Auto-sync**: ArgoCD detecta cambios y sincroniza automáticamente
4. **Verificación**: Revisar estado de aplicaciones en ArgoCD UI

## 📝 Próximos Pasos

- [ ] Configurar Backstage como Developer Portal
- [ ] Implementar políticas de seguridad con OPA Gatekeeper
- [ ] Configurar alertas en Prometheus
- [ ] Integrar OpenTelemetry para tracing distribuido
- [ ] Automatizar backups de configuraciones
- [ ] Implementar RBAC y service accounts específicos

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor, crear un issue antes de enviar pull requests.

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver `LICENSE` para más detalles.

---

**Nota**: Este homelab está diseñado para propósitos de aprendizaje y experimentación. No se recomienda para entornos de producción sin las debidas consideraciones de seguridad y alta disponibilidad.
