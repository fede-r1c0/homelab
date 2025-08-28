# Backstage Setup

## ¿Qué es Backstage?

Backstage es un framework de código abierto para construir portales de desarrolladores. Impulsado por un catálogo de software centralizado, Backstage restaura el orden a tus microservicios e infraestructura y permite que tus equipos de producto envíen código de alta calidad rápidamente sin comprometer la autonomía.

### Componentes principales

1. **Software Catalog**: Catálogo centralizado para gestionar todo tu software
2. **Software Templates**: Plantillas para crear nuevos proyectos rápidamente
3. **TechDocs**: Documentación técnica con enfoque "docs as code"
4. **Plugin Ecosystem**: Ecosistema creciente de plugins de código abierto
5. **Developer Portal**: Portal unificado para toda la infraestructura

### Ventajas principales

- ✅ **Portal unificado**: Centraliza todas las herramientas de infraestructura
- ✅ **Catálogo de software**: Gestión centralizada de microservicios y aplicaciones
- ✅ **Templates**: Estandarización de mejores prácticas de la organización
- ✅ **Documentación**: Enfoque "docs as code" para documentación técnica
- ✅ **Extensibilidad**: Sistema de plugins para funcionalidades personalizadas

## Instalación

### Configuración en ArgoCD

La aplicación está configurada en ArgoCD con los siguientes parámetros:

```yaml
# argocd/applications/backstage.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backstage
  namespace: argocd
  labels:
    project: applications
    phase: "4"
spec:
  project: applications
  sources:
    - repoURL: https://backstage.github.io/charts
      chart: backstage
      targetRevision: 2.6.1
      helm:
        valueFiles:
          - $values/apps/backstage/values.yaml
    - repoURL: https://github.com/fede-r1c0/homelab
      targetRevision: HEAD
      ref: values
      path: apps/backstage
      directory:
        include: "backstage-sealedsecret.yaml"
  destination:
    server: https://kubernetes.default.svc
    namespace: backstage
```

### Configuración de recursos

El archivo `values.yaml` está optimizado para ARM64/Raspberry Pi:

```yaml
# apps/backstage/values.yaml
backstage:
  image:
    registry: "ghcr.io"
    repository: "fede-r1c0/backstage"
    tag: "main-537d73f"
    pullPolicy: "IfNotPresent"
  
  replicas: 1
  
  resources:
    limits:
      memory: 256Mi
      cpu: 200m
    requests:
      memory: 64Mi
      cpu: 100m
  
  extraEnvVarsSecrets: ["backstage-secret"]

service:
  type: LoadBalancer

postgresql:
  enabled: true
  auth:
    username: bn_backstage
    existingSecret: "backstage-secret"
    secretKeys:
      adminPasswordKey: admin-password
      userPasswordKey: user-password
      replicationPasswordKey: replication-password
  architecture: standalone
```

### Configuración de autenticación con Sealed Secrets

Backstage utiliza Sealed Secrets para almacenar credenciales sensibles de forma segura:

```yaml
# apps/backstage/backstage-sealedsecret.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: backstage-secret
  namespace: backstage
spec:
  encryptedData:
    AUTH_GITHUB_CLIENT_ID: <client-id-encriptado>
    AUTH_GITHUB_CLIENT_SECRET: <client-secret-encriptado>
    GITHUB_TOKEN: <github-token-encriptado>
    admin-password: <admin-password-encriptado>
    user-password: <user-password-encriptado>
    replication-password: <replication-password-encriptado>
  template:
    metadata:
      labels:
        app.kubernetes.io/component: postgresql
        app.kubernetes.io/name: backstage
      name: backstage-secret
      namespace: backstage
    type: Opaque
```

## Repositorio personalizado

### Configuración del repositorio

Mi repositorio personalizado de Backstage se encuentra en [https://github.com/fede-r1c0/backstage](https://github.com/fede-r1c0/backstage) donde configuras:

- **IDP (Identity Provider)**: Configuración de autenticación
- **Build de imagen Docker**: Imagen personalizada para el homelab
- **Configuración específica**: Adaptaciones para el entorno

### Flujo de trabajo

1. **Desarrollo**: Modificaciones en el repositorio personalizado
2. **Build**: Generación de imagen Docker con GitHub Actions
3. **Despliegue**: ArgoCD utiliza la imagen desde `ghcr.io/fede-r1c0/backstage`

## Uso básico

### 1. Verificar la instalación

```bash
# Verificar pods de Backstage
kubectl get pods -n backstage

# Verificar servicios expuestos
kubectl get services -n backstage

# Verificar secretos
kubectl get secrets -n backstage
```

### 2. Acceder a la interfaz web

```bash
# Port-forward para Backstage
kubectl port-forward service/backstage 3000:80 -n backstage

# Acceder a http://localhost:3000
# Usar autenticación de GitHub configurada
```

### 3. Verificar la base de datos

```bash
# Verificar pods de PostgreSQL
kubectl get pods -n backstage -l app.kubernetes.io/name=postgresql

# Verificar logs de PostgreSQL
kubectl logs -n backstage -l app.kubernetes.io/name=postgresql
```

## Configuración de autenticación

### Configuración de GitHub OAuth

Backstage utiliza GitHub como proveedor de identidad:

```yaml
# app-config.yaml (en el repositorio personalizado)
auth:
  providers:
    github:
      development:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
        callbackUrl: http://localhost:3000/api/auth/github/handler/frame
      production:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
        callbackUrl: https://backstage.yourdomain.com/api/auth/github/handler/frame
```

### Configuración de GitHub App

Para integración completa con GitHub:

```yaml
# app-config.yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
      apps:
        - appId: 123456
          privateKey: ${GITHUB_APP_PRIVATE_KEY}
          webhookSecret: ${GITHUB_APP_WEBHOOK_SECRET}
          clientId: ${GITHUB_APP_CLIENT_ID}
          clientSecret: ${GITHUB_APP_CLIENT_SECRET}
```

## Catálogo de software

### Configuración del catálogo

```yaml
# app-config.yaml
catalog:
  rules:
    - allow: [Component, System, API, Resource, Location]
  locations:
    # Local example
    - type: url
      target: https://github.com/fede-r1c0/homelab/blob/main/catalog-info.yaml
    # GitHub example
    - type: github-discovery
      target: https://github.com/fede-r1c0/*/blob/main/catalog-info.yaml
```

### Archivo catalog-info.yaml

```yaml
# catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: homelab
  description: Mi homelab personal con Kubernetes
  annotations:
    github.com/project-slug: fede-r1c0/homelab
    backstage.io/techdocs-ref: dir:.
spec:
  type: service
  lifecycle: production
  owner: fede-r1c0
  system: infrastructure
  dependsOn:
    - resource:postgresql
    - resource:redis
```

## Software Templates

### Crear templates personalizados

```yaml
# template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: homelab-service
  title: Homelab Service Template
  description: Template para crear servicios en el homelab
spec:
  owner: fede-r1c0
  type: service
  
  parameters:
    - title: Service Information
      required:
        - serviceName
        - serviceDescription
      properties:
        serviceName:
          title: Service Name
          type: string
          description: Nombre del servicio
        serviceDescription:
          title: Service Description
          type: string
          description: Descripción del servicio
  
  steps:
    - id: template-service
      action: fetch:template
      input:
        url: ./skeleton
        values:
          serviceName: ${{ parameters.serviceName }}
          serviceDescription: ${{ parameters.serviceDescription }}
    
    - id: publish
      action: publish:github
      input:
        repoUrl: github.com?owner=fede-r1c0&repo=${{ parameters.serviceName }}
        defaultBranch: main
        description: ${{ parameters.serviceDescription }}
```

## TechDocs

### Configuración de documentación

```yaml
# app-config.yaml
techdocs:
  builder: 'local'
  generators:
    techdocs: 'docker'
  publisher:
    type: 'local'
    local:
      publishDirectory: './docs'
```

### Estructura de documentación

```bash
docs/
├── 00 - raspberry-pi-setup.md
├── 01 - k3s-installation.md
├── 02 - cilium-installation.md
├── 03 - argocd-installation.md
├── 04 - sealed-secrets-setup.md
├── 05 - metallb-setup.md
├── 05 - prometheus-stack-setup.md
├── 06 - backstage-setup.md
└── 06 - cloudflared-setup.md
```

## Comandos útiles

### Verificar el estado de Backstage

```bash
# Verificar todos los recursos en el namespace backstage
kubectl get all -n backstage

# Verificar logs de Backstage
kubectl logs -n backstage -l app.kubernetes.io/name=backstage

# Verificar configuración de PostgreSQL
kubectl get postgresql -n backstage
```

### Gestión de secretos

```bash
# Ver secretos encriptados
kubectl get sealedsecrets -n backstage

# Ver secretos desencriptados
kubectl get secrets -n backstage

# Ver logs de Sealed Secrets
kubectl logs -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets
```

### Debugging y troubleshooting

```bash
# Ver logs de Backstage en tiempo real
kubectl logs -f -n backstage -l app.kubernetes.io/name=backstage

# Ver logs de PostgreSQL
kubectl logs -n backstage -l app.kubernetes.io/name=postgresql

# Ver eventos del namespace
kubectl get events -n backstage --sort-by='.lastTimestamp'

# Verificar conectividad entre servicios
kubectl exec -n backstage deployment/backstage -- curl postgresql:5432
```

## Mejores prácticas

### 1. **Configuración de recursos**

- Ajusta límites de memoria y CPU según el hardware disponible
- Monitorea el uso de recursos de Backstage
- Considera usar `replicas: 1` para homelabs

### 2. **Seguridad**

- Usa Sealed Secrets para todas las credenciales sensibles
- Implementa RBAC para controlar acceso
- Limita el acceso a la interfaz web con políticas de red

### 3. **Base de datos**

- Configura backups regulares de PostgreSQL
- Monitorea el uso de almacenamiento
- Considera usar almacenamiento persistente

### 4. **Desarrollo**

- Mantén el repositorio personalizado actualizado
- Usa versiones específicas de imágenes para estabilidad
- Documenta cambios en la configuración

## Troubleshooting

### Problema: Backstage no puede conectarse a PostgreSQL

```bash
# Verificar estado de PostgreSQL
kubectl get pods -n backstage -l app.kubernetes.io/name=postgresql

# Verificar logs de PostgreSQL
kubectl logs -n backstage -l app.kubernetes.io/name=postgresql

# Verificar secretos de conexión
kubectl get secret backstage-secret -n backstage -o yaml
```

### Problema: Error de autenticación de GitHub

```bash
# Verificar configuración de OAuth
kubectl get secret backstage-secret -n backstage -o yaml

# Verificar logs de autenticación
kubectl logs -n backstage -l app.kubernetes.io/name=backstage | grep auth

# Verificar configuración de GitHub App
kubectl exec -n backstage deployment/backstage -- env | grep GITHUB
```

### Problema: Imagen no se puede descargar

```bash
# Verificar acceso al registro de contenedores
kubectl describe pod -n backstage -l app.kubernetes.io/name=backstage

# Verificar secretos de pull
kubectl get secrets -n backstage

# Verificar logs de eventos
kubectl get events -n backstage --sort-by='.lastTimestamp'
```

### Problema: Alto uso de recursos

```bash
# Verificar uso de recursos
kubectl top pods -n backstage

# Ajustar límites en values.yaml
# Reducir replicas si es necesario
```

## Configuración avanzada

### Configuración de alta disponibilidad

```yaml
# ha-config.yaml
backstage:
  replicas: 2
  resources:
    limits:
      memory: 512Mi
      cpu: 400m
    requests:
      memory: 128Mi
      cpu: 200m

postgresql:
  architecture: replication
  primary:
    persistence:
      size: 20Gi
  readReplicas:
    persistence:
      size: 10Gi
```

### Configuración de almacenamiento persistente

```yaml
# storage-config.yaml
postgresql:
  primary:
    persistence:
      enabled: true
      size: 20Gi
      storageClassName: "local-path"
      accessModes:
        - ReadWriteOnce
```

### Configuración de métricas y monitoreo

```yaml
# monitoring-config.yaml
backstage:
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /health
    port: http

  podMonitor:
    enabled: true
    interval: 30s
    path: /metrics
    port: http
```

## Recursos adicionales

- [Repositorio oficial](https://github.com/backstage/backstage)
- [Helm Chart](https://artifacthub.io/packages/helm/backstage/backstage)
- [Documentación oficial](https://backstage.io/docs/)
- [Repositorio personalizado](https://github.com/fede-r1c0/backstage)
- [Software Catalog](https://backstage.io/docs/features/software-catalog/)
- [TechDocs](https://backstage.io/docs/features/techdocs/)

## Notas importantes

⚠️ **IMPORTANTE**: Las credenciales de GitHub y PostgreSQL están encriptadas con Sealed Secrets. Mantén un backup de las claves de encriptación.

⚠️ **IMPORTANTE**: Backstage está configurado para usar LoadBalancer. Asegúrate de que MetalLB esté funcionando correctamente.

⚠️ **IMPORTANTE**: La imagen personalizada se construye desde tu repositorio. Mantén actualizado el tag en values.yaml.

⚠️ **IMPORTANTE**: PostgreSQL está configurado en modo standalone. Para producción, considera usar replicación.
