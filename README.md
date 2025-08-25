# 🏠 HomeLab - Kubernetes y GitOps para experimentar

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat&logo=argocd&logoColor=white)](https://argoproj.github.io/argo-cd/)

## 📋 Descripción

Este repo es mi espacio para probar cosas de Kubernetes, GitOps y herramientas CNCF. La idea es ir armando un laboratorio casero donde pueda experimentar, romper, arreglar y aprender sobre la marcha. No hay un objetivo estricto: simplemente ir sumando buenas prácticas, automatización y observabilidad, y de paso dejar todo documentado para que cualquiera pueda replicarlo o adaptarlo.

Funciona sobre una Raspberry Pi 5, pero en realidad podés usar cualquier equipo con Unix/Linux (o WSL en Windows) que cumpla con los requisitos mínimos de hardware.  
El objetivo es que sea fácil de reproducir y modificar.

## 🎯 Objetivos

- Aprender sobre Kubernetes, GitOps y proyectos de la CNCF
- Probar arquitecturas y herramientas reales en un entorno controlado
- Experimentar con observabilidad, seguridad y automatización
- Documentar el proceso para que sirva de referencia a otros

## 🏗️ Arquitectura

### App of Apps con ArgoCD

- `homelab-bootstrap`: la app principal que orquesta todo
- Apps individuales: cada herramienta tiene su propia config en `argocd/applications/`
- Proyectos separados para organizar y aplicar RBAC en `argocd/projects/`
- ArgoCD detecta y gestiona todo desde el repo en `argocd/`

### Stack de tecnologías utilizadas

- **OS**: [Raspberry Pi OS Lite (arm64)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-lite-32-bit)
- **Kubernetes**: [k3s](https://k3s.io/) (liviano, ideal para ARM o equipos chicos)
- **Kubernetes CNI**: [Cilium](https://docs.cilium.io/)
- **Seguridad**: [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- **Exponer servicios a internet**: [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/tunnel-routes/)
- **Observabilidad**: [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/), [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- **GitOps**: [ArgoCD](https://argo-cd.readthedocs.io/)
- **Internal Developer Portal**: [Backstage](https://backstage.io/)

## 📁 Estructura del Repo

```bash
homelab/
├── .github/workflows/           # Validación automática de manifiestos
├── argocd/                      # Configuración de ArgoCD
│   ├── projects/                # Definición de proyectos con RBAC
│   ├── applications/            # Aplicaciones individuales (App of Apps)
├── apps/                        # Configuraciones de aplicaciones (values.yaml)
├── docs/                        # Documentación técnica
└── README.md                    # Este archivo
```

### Apps Incluidas

- **argo**: Bootstrap del homelab con ArgoCD
- **sealed-secrets**: Gestion segura de secretos
- **cloudflare-tunnel**: Exponer servicios a internet con Cloudflare Tunnel
- **prometheus-stack**: Observabilidad completa con Prometheus, Grafana y Alertmanager
- **backstage**: Internal Developer Portal

## 🚀 Implementación

### Instalar k3s

#### Preparación del Sistema

```bash
# Verificar cgroups habilitados
cat /boot/firmware/cmdline.txt | grep cgroup

# Si no están habilitados, agregar:
echo 'cgroup_memory=1 cgroup_enable=memory' | sudo tee -a /boot/firmware/cmdline.txt

# Verificar módulos del kernel
lsmod | grep vxlan

# Si no están disponibles, instalar:
sudo apt install -y linux-modules-extra-raspi
```

#### Instalación de k3s

```bash
# Instalar K3S sin Traefik (usaremos Cilium)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none --disable-network-policy --disable=traefik" sh -

# Verificar instalación
sudo systemctl status k3s

# Configurar kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Verificar cluster
kubectl get nodes
kubectl cluster-info
```

 **Importante:** En caso de utilizar MetalLB desactivar Klipper en la instalación de k3s  (`--disable servicelb`).

#### Configuración de k3s

```bash
# Verificar configuración
cat ~/.kube/config

# Configurar variables de entorno
echo 'export KUBECONFIG=~/.kube/config' >> ~/.zshrc
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.zshrc

# Recargar configuración
source ~/.zshrc

# Verificar acceso
kubectl get nodes
kubectl get pods --all-namespaces
```

### Instalar Cilium

```bash
# Instalar Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalación
helm version

# Agregar repositorio de Cilium
helm repo add cilium https://helm.cilium.io/
helm repo update
```

#### Instalación de Cilium

```bash
# Instalar Cilium con configuración optimizada para Raspberry Pi
helm install cilium cilium/cilium \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=127.0.0.1 \
  --set k8sServicePort=6443 \
  --set operator.replicas=1 \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.ui.service.type=LoadBalancer \
  --set prometheus.enabled=true \
  --set operator.prometheus.enabled=true

# Verificar instalación
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl get pods -n kube-system -l name=cilium-operator
```

#### Verificación del Setup

```bash
# Instalar Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-arm64.tar.gz
tar xzvfC cilium-linux-arm64.tar.gz /usr/local/bin
rm cilium-linux-arm64.tar.gz

# Verificar Cilium
cilium status
cilium connectivity test

# Verificar métricas
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl get pods -n kube-system -l k8s-app=hubble-relay
```

### Instalar ArgoCD

Agregar repositorio de Helm de ArgoCD

```bash
# Agregar repositorio oficial de ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

```bash
# Instalar ArgoCD con configuración personalizada
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values apps/argo/argocd/values.yaml \
  --wait
```

#### Verificación de la Instalación

```bash
# Verificar pods
kubectl get pods -n argocd

# Verificar servicios
kubectl get svc -n argocd

# Verificar aplicaciones
kubectl get applications -n argocd
```

#### Obtener contraseña de Admin

```bash
# Obtener contraseña inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Resetear contraseña si es necesario
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData":{"admin.password":"nueva-contraseña"}}'
```

#### Acceder a ArgoCD

```bash
# Port-forward para exponer el servicio de ArgoCD en el puerto 8080 de la Raspberry Pi
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Acceder desde otro equipo al puerto 8080 de la Raspberry Pi via SSH  

```bash
# Acceso via SSH al puerto 8080 de la Raspberry Pi
ssh -L 8080:localhost:8080 user@raspberrypi.hostname

# Abrir navegador en http://localhost:8080
# Usuario: admin
# Contraseña: [obtenida en paso anterior]
```

### Bootstrap del Homelab

En este punto ya tenemos ArgoCD instalado y funcionando. Ahora vamos a configurar el bootstrap del homelab.  
Para crear la application `homelab-bootstrap` vamos a utilzar el chart de helm `argocd-apps`. Esta application se encargara de instalar las aplicaciones y proyectos de ArgoCD que se encuentran en el directorio `argocd`.

```bash
# Instalar el chart de helm argocd-apps
helm install argocd-apps argo/argocd-apps \
  --namespace argocd \
  --create-namespace \
  --values apps/argo/argocd-apps/values.yaml \
  --wait
```

## 📚 Documentación Detallada

Ya que este README es solo una vista general, la documentación completa está en el directorio `docs/`:

- **[Raspberry Pi Setup](docs/RASPBERRYPI_SETUP.md)** - Configurar tu Pi u otro Linux con arm64
- **[k3s Setup](docs/K3S_CILIUM_SETUP.md)** - Instalar el cluster Kubernetes
- **[ArgoCD Setup](docs/ARGOCD_SETUP.md)** - Configurar GitOps y el patrón App of Apps
- **[Cloudflare Tunnel](docs/CLOUDFLARED_SETUP.md)** - Exponer servicios a internet de forma segura

## 🔧 Personalización

### Agregar Nuevas Apps

1. Crear directorio en `apps/` con tu `values.yaml`
2. Crear app en `argocd/applications/`
3. Commit y push → ArgoCD la detecta automáticamente

### Modificar Configuración

- **Apps**: Edita `values.yaml` en `apps/`
- **ArgoCD**: Modifica archivos en `argocd/`

## 🚨 Troubleshooting Rápido

**App en OutOfSync:**

```bash
kubectl get applications -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

**Pods no arrancan:**

```bash
kubectl describe pod <nombre-del-pod> -n <namespace>
kubectl get events --sort-by=.metadata.creationTimestamp
```

**ArgoCD no responde:**

```bash
kubectl get pods -n argocd
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f
```

## 🌐 Acceso a Servicios

Con Cloudflare Tunnel configurado se pueden exponer los servicios internos del cluster a internet con un dominio propio configurado en Cloudflare. En mi caso, los servicios se exponen en los siguientes dominios:

| Servicio | URL |
|----------|-----|
| ArgoCD | <https://argocd.feder1c0.tech> |
| Grafana | <https://grafana.feder1c0.tech> |
| Backstage | <https://backstage.feder1c0.tech> |

## 🎯 Próximos Pasos

- [ ] Configurar Backstage como Developer Portal
- [ ] Configurar alertas en Prometheus
- [ ] Implementar backup automático
- [ ] Probar más proyectos de la CNCF

## 📜 Licencia

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
**Este proyecto está bajo la licencia Creative Commons BY-NC-SA 4.0.**

### ✅ **¿Qué Puedes Hacer?**

- **Usar y aprender** del proyecto para fines personales/educativos
- **Modificar y adaptar** el código para tus necesidades
- **Crear trabajos derivados** basados en este proyecto
- **Distribuir versiones modificadas** (bajo la misma licencia)
- **Contribuir mejoras** al proyecto original
- **Compartir y colaborar** con la comunidad

### ❌ **¿Qué NO Puedes Hacer?**

- **Usar para fines comerciales** (bootcamps de pago, apps comerciales)
- **Remover la atribución** al autor original
- **Distribuir bajo términos diferentes** de licencia
- **Usar en proyectos comerciales** sin permiso

### 📋 **¿Qué DEBES Hacer?**

- **Dar crédito apropiado** al autor original [https://github.com/fede-r1c0](https://github.com/fede-r1c0)
- **Proporcionar un enlace** a la licencia
- **Licenciar trabajos derivados** bajo los mismos términos (BY-NC-SA 4.0)
- **Indicar si hiciste modificaciones**

## 🤝 Contribuir

**¡Este proyecto fomenta activamente las contribuciones!** 🚀

- **✅ Modificaciones permitidas** - Podés mejorar y adaptar el código
- **✅ Derivados fomentados** - Creá tu propia versión del proyecto
- **✅ Colaboración abierta** - Contribuí mejoras al proyecto original

**Guía completa:** [CONTRIBUTING.md](CONTRIBUTING.md) | **Fork y contribuye:** [GitHub](https://github.com/fede-r1c0/homelab)

## 📚 Recursos

- [k3s Docs](https://docs.k3s.io/)
- [Cilium Docs](https://docs.cilium.io/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)

---

**¡Listo! Ahora tenés un homelab Kubernetes completo y automatizado.** 🚀
