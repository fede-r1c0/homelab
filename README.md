# 🏠 HomeLab - Kubernetes y GitOps para experimentar

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
- **Kubernetes**: K3S (liviano, ideal para ARM o equipos chicos)
- **CNI**: Cilium
- **Load Balancer**: MetalLB
- **Certificados**: cert-manager
- **Observabilidad**: Prometheus, Grafana, Loki, Tempo, Hubble
- **GitOps**: ArgoCD
- **Seguridad**: OPA Gatekeeper, Cilium Network Policies, Sealed Secrets
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
├── policies/                    # Políticas OPA para validación
└── README.md                    # Este archivo
```

### Apps Incluidas

- **00-sealed-secrets**: Gestión segura de secretos
- **01-metallb**: Load balancer para servicios
- **02-cert-manager**: Certificados TLS automáticos
- **03-opa-gatekeeper**: Políticas de seguridad
- **04-prometheus-stack**: Observabilidad completa
- **05-backstage**: Developer Portal

> **Nota**: Las apps se instalan en este orden para respetar dependencias:

## 🚀 Implementación

### Setup Inicial

**Opción 1: Script Automático (Recomendado)**

```bash
# Hacer ejecutable y ejecutar
chmod +x scripts/bootstrap-argocd.sh
./scripts/bootstrap-argocd.sh
```

**Opción 2: Manual via UI de ArgoCD**

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

**Verificar estado rápidamente:**
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
| ArgoCD | http://cluster-ip | admin / [ver secret] |
| Grafana | http://cluster-ip | admin / prom-operator |
| Prometheus | http://cluster-ip:9090 | - |
| Backstage | http://cluster-ip:7007 | - |

## 🎯 Próximos Pasos

- [ ] Configurar Backstage como Developer Portal
- [ ] Agregar políticas de OPA Gatekeeper
- [ ] Configurar alertas en Prometheus
- [ ] Implementar backup automático
- [ ] Probar más proyectos de la CNCF

## 🤝 Contribuir

Si te sirve esto o querés mejorarlo:

1. Fork del repo
2. Crear branch para tu feature
3. Commit y push
4. Abrir Pull Request

## 📜 Licencia

Este proyecto está bajo **Creative Commons BY-NC-SA 4.0**.

**✅ Permite:** Uso personal/educativo, modificaciones, contribuciones
**❌ Prohíbe:** Uso comercial (bootcamps, apps comerciales)
**📋 Requiere:** Atribución al autor, misma licencia para derivados

**Resumen rápido:** [LICENSE](LICENSE) | **Detalles:** [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

## 📚 Recursos

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [k3s Docs](https://docs.k3s.io/)
- [Cilium Docs](https://docs.cilium.io/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)

---

**¡Listo! Ahora tenés un homelab Kubernetes completo y automatizado.** 🚀
