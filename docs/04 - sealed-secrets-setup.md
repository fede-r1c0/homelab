# Sealed Secrets Setup

## ¿Qué son Sealed Secrets?

Sealed Secrets es una solución de Kubernetes que permite almacenar secretos de forma segura en el control de versiones (Git). Funciona mediante un controlador que:

1. **Encripta** secretos usando criptografía asimétrica antes de almacenarlos en Git
2. **Desencripta** automáticamente los secretos cuando se despliegan en el cluster
3. **Mantiene** los secretos originales seguros y nunca los expone en texto plano

### Ventajas principales

- ✅ **Seguridad**: Los secretos nunca se almacenan en texto plano en Git
- ✅ **GitOps**: Permite gestionar secretos de forma declarativa
- ✅ **Automatización**: El controlador maneja la encriptación/desencriptación automáticamente
- ✅ **Auditoría**: Mantiene un historial completo de cambios en Git

## Instalación

### Configuración en ArgoCD

La aplicación está configurada en ArgoCD con los siguientes parámetros:

```yaml
# argocd/applications/sealed-secrets.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sealed-secrets
  namespace: argocd
  labels:
    project: security
    phase: "1"
spec:
  project: security
  source:
    repoURL: https://bitnami-labs.github.io/sealed-secrets
    chart: sealed-secrets
    targetRevision: 2.17.3
    helm:
      valueFiles:
        - https://raw.githubusercontent.com/fede-r1c0/homelab/main/apps/sealed-secrets/values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: sealed-secrets
```

### Configuración de recursos

El archivo `values.yaml` está optimizado para ARM64/Raspberry Pi:

```yaml
# apps/sealed-secrets/values.yaml
resources:
  requests:
    memory: 64Mi
    cpu: 50m
  limits:
    memory: 128Mi
    cpu: 100m
```

## Uso básico

### 1. Instalar kubeseal (CLI)

```bash
# macOS
brew install kubeseal

# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.31.0/kubeseal-0.31.0-linux-amd64.tar.gz
tar -xzf kubeseal-0.31.0-linux-amd64.tar.gz
sudo mv kubeseal /usr/local/bin/
```

### 2. Crear un secreto normal

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: default
type: Opaque
data:
  username: dXNlcm5hbWU=  # base64 encoded
  password: cGFzc3dvcmQ=   # base64 encoded
```

### 3. Encriptar el secreto

```bash
# Encriptar el secreto
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# O especificar nombre el namespace del controlador si es diferente
kubeseal --controller-name sealed-secrets --controller-namespace sealed-secrets --format yaml < secret.yaml > secret-sealedsecret.yaml
```

### 4. Aplicar el SealedSecret

Para probar localmente en el cluster podes aplicar el archivo `secret-sealedsecret.yaml` con el siguiente comando:

```bash
# Localmente
kubectl apply -f secret-sealedsecret.yaml
```

Para agregar el archivo a git y que ArgoCD lo aplique al cluster es necesario subir el secret encriptado al repositorio de tu aplicación:

```bash
# Remotamente
git add secret-sealedsecret.yaml
git commit -m "chore: add secret-sealedsecret.yaml"
git push
```

## Ejemplos prácticos

### Ejemplo 1: Credenciales de base de datos

```yaml
# db-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: default
type: Opaque
data:
  username: cG9zdGdyZXM=  # postgres
  password: bXlwYXNzd29yZA==  # mypassword
  host: bG9jYWxob3N0  # localhost
  port: NTQzMg==  # 5432
```

### Ejemplo 2: Token de API

```yaml
# api-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-token
  namespace: default
type: Opaque
data:
  token: Z2hwX3Rva2VuX2hlcmU=  # github_token_here
```

### Ejemplo 3: Configuración de aplicación

```yaml
# app-config-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-config
  namespace: default
type: Opaque
data:
  database_url: cG9zdGdyZXM6Ly9sb2NhbGhvc3Q6NTQzMi9teWRi
  redis_url: cmVkaXM6Ly9sb2NhbGhvc3Q6NjM3OQ==
  jwt_secret: bXlqd3RzZWNyZXQ=
```

## Comandos útiles

### Verificar el estado del controlador

```bash
# Verificar pods del controlador
kubectl get pods -n sealed-secrets

# Verificar logs del controlador
kubectl logs -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets

# Verificar CRDs instalados
kubectl get crd | grep sealedsecrets
```

### Gestión de claves de encriptación

```bash
# Ver claves de encriptación
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key

# Backup de claves (IMPORTANTE para recuperación)
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > backup-keys.yaml
```

### Re-encriptar secretos

```bash
# Re-encriptar con la clave más reciente
kubeseal --re-encrypt < sealed-secret.yaml > new-sealed-secret.yaml
```

## Mejores prácticas

### 1. **Gestión de claves**

- Haz backup regular de las claves de encriptación
- Rota las claves periódicamente
- Almacena las claves de backup en un lugar seguro

### 2. **Organización**

- Usa namespaces para organizar secretos por aplicación
- Nombra los secretos de forma descriptiva
- Documenta qué secretos necesita cada aplicación

### 3. **Seguridad**

- Nunca commits secretos en texto plano
- Usa políticas de RBAC para controlar acceso
- Revisa regularmente los permisos de acceso

### 4. **Monitoreo**

- Configura alertas para fallos del controlador
- Monitorea el uso de recursos del controlador
- Revisa logs regularmente para detectar problemas

## Troubleshooting

### Problema: Controlador no puede desencriptar

```bash
# Verificar estado del controlador
kubectl get pods -n sealed-secrets

# Verificar logs del controlador
kubectl logs -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets

# Verificar claves de encriptación
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key
```

### Problema: Error de permisos

```bash
# Verificar RBAC
kubectl get clusterrole,clusterrolebinding | grep sealed-secrets

# Verificar permisos en el namespace
kubectl auth can-i create secrets --namespace default
```

### Problema: kubeseal no puede conectarse

```bash
# Verificar que el controlador esté ejecutándose
kubectl get pods -n sealed-secrets

# Verificar el namespace del controlador
kubectl get pods -n sealed-secrets -o wide
```

## Recursos adicionales

- [Repositorio oficial](https://github.com/bitnami-labs/sealed-secrets)
- [Helm Chart](https://artifacthub.io/packages/helm/bitnami-labs/sealed-secrets)
- [Documentación oficial](https://github.com/bitnami-labs/sealed-secrets#readme)
- [Slack de la comunidad](https://kubernetes.slack.com/messages/sealed-secrets)

## Notas importantes

⚠️ **IMPORTANTE**: Las claves de encriptación son críticas para la seguridad. Si las pierdes, no podrás desencriptar los secretos existentes.

⚠️ **IMPORTANTE**: Sealed Secrets no es un sistema de backup de secretos. Es una herramienta para gestionar secretos de forma segura en Git.

⚠️ **IMPORTANTE**: Los secretos desencriptados solo existen en el cluster. No se almacenan permanentemente en texto plano.
