# MetalLB Setup

## ¿Qué es MetalLB?

MetalLB es una implementación de balanceador de carga para clusters de Kubernetes en bare metal que utiliza protocolos de enrutamiento estándar. En un entorno de homelab, permite exponer servicios de Kubernetes a la red local sin necesidad de un balanceador de carga externo.

### Componentes principales

1. **Controller**: Gestiona la asignación de direcciones IP y coordina con el speaker
2. **Speaker**: Implementa el protocolo de anuncio de direcciones IP (ARP/NDP para L2, BGP para L3)
3. **IP Address Pool**: Define el rango de direcciones IP disponibles para servicios LoadBalancer

### Ventajas principales

- ✅ **Bare Metal**: Funciona en clusters sin balanceadores de carga externos
- ✅ **Protocolos estándar**: Utiliza ARP/NDP (L2) o BGP (L3)
- ✅ **Integración nativa**: Funciona como un balanceador de carga estándar de Kubernetes
- ✅ **Flexibilidad**: Soporta múltiples modos de operación

## Instalación

### Configuración en ArgoCD

La aplicación está configurada en ArgoCD con los siguientes parámetros:

```yaml
# argocd/applications/metallb.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metallb
  namespace: argocd
  labels:
    project: bootstrap
    phase: "2"
spec:
  project: bootstrap
  sources:
    - repoURL: https://metallb.github.io/metallb
      chart: metallb
      targetRevision: 0.15.2
      helm:
        valueFiles:
          - $values/apps/metallb/values.yaml
    - repoURL: https://github.com/fede-r1c0/homelab
      targetRevision: HEAD
      ref: values
    - repoURL: https://github.com/fede-r1c0/homelab
      targetRevision: HEAD
      path: apps/metallb
      directory:
        include: "metallb-config.yaml"
  destination:
    server: https://kubernetes.default.svc
    namespace: metallb-system
```

### Configuración de recursos

El archivo `values.yaml` está optimizado para ARM64/Raspberry Pi:

```yaml
# apps/metallb/values.yaml
controller:
  resources:
    requests:
      memory: 64Mi
      cpu: 100m
    limits:
      memory: 128Mi
      cpu: 200m
  replicaCount: 1

speaker:
  resources:
    requests:
      memory: 64Mi
      cpu: 100m
    limits:
      memory: 128Mi
      cpu: 200m
  hostNetwork: true
  daemonSet:
    enabled: true

# Deshabilitado para modo L2 (solo necesario para BGP)
frr:
  enabled: false
frrk8s:
  enabled: false
```

## Configuración del pool de IPs

### Configuración L2 (Recomendada para homelab)

```yaml
# apps/metallb/metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250  # Ajusta según tu red local
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
```

### Configuración BGP (Para redes más complejas)

```yaml
# apps/metallb/metallb-config-bgp.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250 # Ajusta según tu red local
---
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: default
  namespace: metallb-system
spec:
  myASN: 64500
  peerASN: 64500
  peerAddress: 192.168.1.1 # Ajusta según tu red local
---
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
  peers:
  - default
```

## Uso básico

### 1. Verificar la instalación

```bash
# Verificar pods del controlador
kubectl get pods -n metallb-system

# Verificar el speaker (debe ejecutarse en cada nodo)
kubectl get pods -n metallb-system -l app.kubernetes.io/component=speaker

# Verificar CRDs instalados
kubectl get crd | grep metallb
```

### 2. Crear un servicio LoadBalancer

```yaml
# example-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: example-service
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: example-app
```

### 3. Aplicar el servicio

```bash
kubectl apply -f example-service.yaml
```

### 4. Verificar la IP asignada

```bash
# Ver la IP asignada por MetalLB
kubectl get service example-service

# Ver logs del controlador para debugging
kubectl logs -n metallb-system -l app=metallb-controller
```

## Ejemplos prácticos

### Ejemplo 1: Aplicación web simple

```yaml
# web-app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app
  namespace: default
  annotations:
    metallb.universe.tf/allow-shared-ip: web-app
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
  selector:
    app: web-app
```

### Ejemplo 2: API con múltiples puertos

```yaml
# api-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: default
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: metrics
    port: 9090
    targetPort: 9090
  selector:
    app: api-server
```

### Ejemplo 3: Base de datos con IP fija

```yaml
# db-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-db
  namespace: database
  annotations:
    metallb.universe.tf/loadBalancerIPs: 192.168.1.241
spec:
  type: LoadBalancer
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgres
```

## Comandos útiles

### Verificar el estado de MetalLB

```bash
# Verificar estado del controlador
kubectl get pods -n metallb-system

# Verificar logs del controlador
kubectl logs -n metallb-system -l app=metallb-controller

# Verificar logs del speaker
kubectl logs -n metallb-system -l app=metallb-speaker

# Verificar configuración del pool de IPs
kubectl get ipaddresspools -n metallb-system
```

### Gestión de configuraciones

```bash
# Ver anuncios L2
kubectl get l2advertisements -n metallb-system

# Ver anuncios BGP
kubectl get bgpadvertisements -n metallb-system

# Ver peers BGP
kubectl get bgppeers -n metallb-system

# Ver configuración detallada
kubectl describe ipaddresspool first-pool -n metallb-system
```

### Debugging y troubleshooting

```bash
# Ver eventos relacionados con MetalLB
kubectl get events -n metallb-system

# Ver logs en tiempo real
kubectl logs -f -n metallb-system -l app=metallb-controller

# Verificar conectividad de red
kubectl exec -n metallb-system deployment/metallb-controller -- ping 192.168.1.1
```

## Mejores prácticas

### 1. **Planificación de red**

- Reserva un rango de IPs específico para MetalLB
- Evita conflictos con DHCP y otras asignaciones estándar
- Documenta la configuración de red del homelab

### 2. **Configuración de recursos**

- Ajusta límites de recursos según el hardware disponible
- Monitorea el uso de CPU y memoria
- Considera usar `replicaCount: 1` para clusters de un solo nodo

### 3. **Seguridad**

- Usa namespaces para aislar servicios
- Implementa políticas de red con Cilium o Calico
- Limita el acceso a servicios expuestos

### 4. **Monitoreo**

- Configura alertas para fallos del controlador
- Monitorea la asignación de IPs
- Revisa logs regularmente para detectar problemas

## Troubleshooting

### Problema: No se asignan IPs a los servicios

```bash
# Verificar que MetalLB esté funcionando
kubectl get pods -n metallb-system

# Verificar configuración del pool de IPs
kubectl get ipaddresspools -n metallb-system

# Verificar anuncios L2/BGP
kubectl get l2advertisements -n metallb-system

# Ver logs del controlador
kubectl logs -n metallb-system -l app=metallb-controller
```

### Problema: Servicios no son accesibles desde la red

```bash
# Verificar que la IP esté asignada
kubectl get service

# Verificar conectividad de red
ping <ip-asignada>

# Verificar logs del speaker
kubectl logs -n metallb-system -l app=metallb-speaker
```

### Problema: Conflictos de IP

```bash
# Verificar IPs en uso
kubectl get service --all-namespaces -o wide

# Verificar configuración del pool
kubectl describe ipaddresspool -n metallb-system

# Limpiar servicios con problemas
kubectl delete service <nombre-servicio>
```

### Problema: Alto uso de recursos

```bash
# Verificar uso de recursos
kubectl top pods -n metallb-system

# Ajustar límites en values.yaml
# Reducir replicaCount si es necesario
```

## Configuración avanzada

### Configuración de múltiples pools

```yaml
# multiple-pools.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-1
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.245
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-2
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.246-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: pool-1-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool-1
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: pool-2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool-2
```

### Configuración con anotaciones

```yaml
# service-with-annotations.yaml
apiVersion: v1
kind: Service
metadata:
  name: annotated-service
  namespace: default
  annotations:
    metallb.universe.tf/allow-shared-ip: shared-ip-pool
    metallb.universe.tf/loadBalancerIPs: 192.168.1.241
    metallb.universe.tf/address-pool: pool-1
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: annotated-app
```

## Recursos adicionales

- [Repositorio oficial](https://github.com/metallb/metallb)
- [Helm Chart](https://artifacthub.io/packages/helm/metallb/metallb)
- [Documentación oficial](https://metallb.universe.tf/)
- [Guía de configuración](https://metallb.universe.tf/configuration/)
- [Troubleshooting](https://metallb.universe.tf/troubleshooting/)

## Notas importantes

⚠️ **IMPORTANTE**: Asegúrate de que el rango de IPs configurado no entre en conflicto con tu router DHCP.

⚠️ **IMPORTANTE**: Para clusters de un solo nodo, usa `replicaCount: 1` y deshabilita FRR.

⚠️ **IMPORTANTE**: El modo L2 es más simple y recomendado para homelabs, mientras que BGP es para redes empresariales más complejas.

⚠️ **IMPORTANTE**: MetalLB solo funciona en clusters bare metal. En clouds públicos, usa los balanceadores de carga nativos.
