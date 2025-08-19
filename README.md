# 🏠 HomeLab - Kubernetes y GitOps para experimentar

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=flat&logo=argocd&logoColor=white)](https://argoproj.github.io/argo-cd/)

## 📋 Descripción

Este repo es mi espacio para probar cosas de Kubernetes, GitOps y herramientas CNCF. La idea es ir armando un laboratorio casero donde pueda experimentar, romper, arreglar y aprender sobre la marcha. No hay un objetivo estricto: simplemente ir sumando buenas prácticas, automatización y observabilidad, y de paso dejar todo documentado para que cualquiera pueda replicarlo o adaptarlo.

Funciona sobre una Raspberry Pi 5, pero en realidad podés usar cualquier equipo con Linux (o WSL en Windows, o macOS) que cumpla con los requisitos mínimos de hardware. El objetivo es que sea fácil de reproducir y modificar.

## 🎯 Objetivos

- Aprender sobre Kubernetes, GitOps y proyectos de la CNCF
- Probar arquitecturas y herramientas reales en un entorno controlado
- Experimentar con observabilidad, seguridad y automatización
- Documentar el proceso para que sirva de referencia a otros

## 🏗️ Arquitectura

### App of Apps con ArgoCD

- `homelab-bootstrap`: la app principal que orquesta todo
- Apps individuales: cada herramienta tiene su propia config
- Proyectos separados para organizar y aplicar RBAC
- ArgoCD detecta y gestiona todo desde el repo

### Stack de Tecnologías

- **OS**: Ubuntu Server (ARM64) o cualquier Linux
- **Kubernetes**: k3s (liviano, ideal para ARM o equipos chicos)
- **CNI**: Cilium
- **Load Balancer**: MetalLB
- **Certificados**: cert-manager
- **Observabilidad**: Prometheus, Grafana, Alertmanager
- **GitOps**: ArgoCD
- **Seguridad**: Cilium Network Policies, Sealed Secrets
- **Internal Developer Portal**: Backstage

## 📁 Estructura del Repo

```bash
homelab/
├── .github/workflows/           # Validación automática de manifiestos
├── argocd/                      # Configuración de ArgoCD
│   ├── projects/                # Definición de proyectos con RBAC
│   ├── applications/            # Aplicaciones individuales (App of Apps)
│   └── application-sets/        # ApplicationSets para gestión masiva
├── apps/                        # Configuraciones de aplicaciones (values.yaml)
├── scripts/                     # Scripts de automatización
├── docs/                        # Documentación técnica
└── README.md                    # Este archivo
```

### Apps Incluidas

- **00-sealed-secrets**: Gestión segura de secretos
- **01-metallb**: Load balancer para servicios
- **02-cert-manager**: Certificados TLS automáticos
- **03-prometheus-stack**: Observabilidad completa
- **04-backstage**: Developer Portal

> **Nota**: Las apps se instalan en este orden para respetar dependencias:

## 🚀 Implementación

### Setup Inicial

#### Opción 1: Script Automático (Recomendado)

```bash
# Hacer ejecutable y ejecutar
chmod +x scripts/bootstrap-argocd.sh
./scripts/bootstrap-argocd.sh
```

#### Opción 2: Manual via UI de ArgoCD

1. Agregar repo `https://github.com/fede-r1c0/homelab` en ArgoCD
2. Crear app `homelab-bootstrap` apuntando a `argocd/`
3. ArgoCD auto-descubre y gestiona todo lo demás

### Cómo Funciona

- **ArgoCD lee** tu repo automáticamente
- **Crea proyectos** con RBAC granular
- **Despliega apps** en el orden correcto (dependencias)
- **Sincroniza** cambios automáticamente
- **Auto-healing** si algo se rompe
- **GitOps** completo: todo se gestiona desde el repo

### Comandos Útiles

#### Verificar estado rápidamente

```bash
./scripts/quick-check.sh
```

**Comandos básicos:**

```bash
# Ver apps de ArgoCD
kubectl get applications -n argocd

# Ver pods
kubectl get pods -n argocd

# Logs de ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

## 🔍 Validación y CI/CD

### Quick Start

```bash
# Instalar herramientas de validación
make install-hooks

# Validar cambios antes de commit
make validate

# Ver todos los comandos disponibles
make help
```

### Características

- **Pre-commit hooks**: Validación automática al hacer commit
- **GitHub Actions**: CI/CD pipeline eficiente (~90 segundos)
- **Validación inteligente**: Solo archivos cambiados
- **Seguridad**: Escaneo con Trivy en rama main
- **Performance**: Jobs paralelos y cache optimizado

### Herramientas

- `yamllint` - Validación de sintaxis YAML
- `helm` - Validación de templates (opcional)
- `kubeconform` - Validación de schemas K8s (opcional)
- `trivy` - Escaneo de seguridad

Ver [Guía de Validación](scripts/README-VALIDATION.md) para configuración completa.

## 📚 Documentación Detallada

Ya que este README es solo una vista general, la documentación completa está en el directorio `docs/`:

- **[Raspberry Pi Setup](docs/RASPBERRYPI_SETUP.md)** - Configurar tu Pi u otro Linux con arm64
- **[k3s Setup](docs/K3S_CILIUM_SETUP.md)** - Instalar el cluster Kubernetes
- **[Cilium Setup](docs/K3S_CILIUM_SETUP.md)** - Instalar el cluster Kubernetes
- **[ArgoCD Setup](docs/ARGOCD_SETUP.md)** - Configurar GitOps y el patrón App of Apps

## 🔧 Personalización

### Agregar Nuevas Apps

1. Crear directorio en `apps/` con tu `values.yaml`
2. Crear app en `argocd/applications/`
3. Commit y push → ArgoCD la detecta automáticamente

### Modificar Configuración

- **Apps**: Edita `values.yaml` en `apps/`
- **ArgoCD**: Modifica archivos en `argocd/`
- **Scripts**: Personaliza `scripts/config.env`

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

Una vez que todo esté funcionando:

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| ArgoCD | <http://cluster-ip> | admin / [ver secret] |
| Grafana | <http://cluster-ip> | admin / prom-operator |
| Prometheus | <http://cluster-ip:9090> | - |
| Backstage | <http://cluster-ip:7007> | - |

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

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [k3s Docs](https://docs.k3s.io/)
- [Cilium Docs](https://docs.cilium.io/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)

---

**¡Listo! Ahora tenés un homelab Kubernetes completo y automatizado.** 🚀
