# 🚀 Scripts de Automatización - Homelab Kubernetes

## 📋 **Descripción**

Este directorio contiene scripts de automatización para configurar y gestionar tu Kubernetes homelab con ArgoCD.

## 🎯 **Scripts Disponibles**

### **1. `simple-bootstrap.sh` - Bootstrap Principal**

**Propósito**: Configuración automática completa de ArgoCD
**Uso**:

```bash
chmod +x scripts/simple-bootstrap.sh
./scripts/simple-bootstrap.sh
```

**Funcionalidades**:

- ✅ Verificación de pre-requisitos
- ✅ Verificación del estado de ArgoCD
- ✅ Agregar repositorio automáticamente
- ✅ Crear aplicación bootstrap
- ✅ Sincronización automática
- ✅ Verificación del estado final

### **2. `quick-check.sh` - Verificación Rápida**

**Propósito**: Verificación rápida del estado del cluster
**Uso**:

```bash
chmod +x scripts/quick-check.sh
./scripts/quick-check.sh
```

**Funcionalidades**:

- ✅ Estado del cluster
- ✅ Estado de los nodos
- ✅ Estado de ArgoCD
- ✅ Estado de las aplicaciones
- ✅ Servicios expuestos
- ✅ Recursos del sistema

### **3. `config.env` - Archivo de Configuración**

**Propósito**: Configuración centralizada para todos los scripts
**Variables principales**:

- `REPO_URL`: URL del repositorio GitHub
- `ARGOCD_NAMESPACE`: Namespace de ArgoCD
- `BOOTSTRAP_APP_NAME`: Nombre de la aplicación bootstrap
- `ENABLE_COLORS`: Habilitar colores en output
- `VERBOSE`: Modo verbose

## 🚀 **Flujo de Trabajo Recomendado**

### **Setup Inicial**

```bash
# 1. Bootstrap automático
./scripts/bootstrap-argocd.sh

# 2. Verificar estado
./scripts/quick-check.sh
```

### **Uso Diario**

```bash
# Verificar estado rápidamente
./scripts/quick-check.sh

# Si hay problemas, revisar logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### **Mantenimiento**

```bash
# Verificar aplicaciones
kubectl get applications -n argocd

# Sincronizar manualmente si es necesario
argocd app sync homelab-bootstrap
```

## 🔧 **Personalización**

### **Modificar Configuración**

Edita `config.env` para cambiar:

- URLs de repositorios
- Timeouts
- Comportamiento de los scripts

### **Agregar Nuevos Scripts**

1. Crear script en este directorio
2. Agregar documentación aquí
3. Actualizar este README

## 🚨 **Troubleshooting**

### **Problemas Comunes**

1. **Script no ejecutable**

   ```bash
   chmod +x scripts/*.sh
   ```

2. **Permisos de kubectl**

   ```bash
   kubectl auth can-i get pods --all-namespaces
   ```

3. **ArgoCD no accesible**

   ```bash
   kubectl get pods -n argocd
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
   ```

### **Logs de Diagnóstico**

```bash
# Logs de ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Logs de aplicaciones específicas
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## 📚 **Recursos Adicionales**

- [ArgoCD CLI Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd/)
- [Kubernetes kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Bash Scripting Best Practices](https://google.github.io/styleguide/shellguide.html)

## 🤝 **Contribución**

Para mejorar los scripts:

1. Mantener compatibilidad con bash
2. Agregar manejo de errores robusto
3. Documentar nuevas funcionalidades
4. Seguir el estilo de código existente

---
