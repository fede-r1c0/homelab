# 🚀 K3S y Cilium Setup para Homelab Kubernetes

## 📋 **Descripción**

Esta guía detalla la instalación y configuración de K3S (Kubernetes ligero) y Cilium CNI en Raspberry Pi 5. El setup está optimizado para entornos de homelab con recursos limitados, proporcionando una base sólida para experimentar con tecnologías cloud-native.

## 🎯 **Objetivos del Setup**

- **Cluster Kubernetes funcional** en Raspberry Pi 5 o Linux arm64
- **CNI avanzado** con Cilium y eBPF
- **Base para GitOps** con ArgoCD
- **Entorno de aprendizaje** para DevOps y SRE

## 🛠️ **Prerrequisitos**

### **Sistema Base**

- ✅ Raspberry Pi OS (Linux arm64)
- ✅ 8GB RAM (mínimo 4GB)
- ✅ 64GB+ Almacenamiento
- ✅ Conexión de red estable
- ✅ Acceso SSH configurado

### **Software Base**

- ✅ Sistema actualizado
- ✅ Herramientas de desarrollo instaladas
- ✅ SSH configurado y funcionando
- ✅ Cgroups habilitados

## 🚀 **Instalación de k3s**

### **1. Preparación del Sistema**

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

### **2. Instalación de k3s**

#### **⚠️ Importante: Deshabilitar Klipper para MetalLB**

K3s viene con **Klipper** (su propio LoadBalancer), que entra en conflicto con **MetalLB**. Según la [documentación oficial de MetalLB](https://metallb.io/configuration/k3s/), debemos deshabilitar Klipper con `--disable servicelb`.

```bash
# Instalar K3S sin Traefik (usaremos Cilium) y sin Klipper (usaremos MetalLB)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=none --disable-network-policy --disable servicelb --disable=traefik" sh -

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

### **3. Configuración de K3S**

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

## 🔧 **Instalación de Cilium CNI**

### **1. Preparación para Cilium**

```bash
# Verificar que no hay CNI activo
kubectl get pods -n kube-system | grep -E "(flannel|calico|weave)"

# Verificar que K3S está funcionando
kubectl get nodes -o wide
```

### **2. Instalación de Helm**

```bash
# Instalar Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalación
helm version

# Agregar repositorio de Cilium
helm repo add cilium https://helm.cilium.io/
helm repo update
```

### **3. Instalación de Cilium**

```bash
# Instalar Cilium con configuración optimizada para Raspberry Pi
helm install cilium cilium/cilium \
  --namespace kube-system \
  --set kubeProxyReplacement=strict \
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

## 🔍 **Verificación del Setup**

### **1. Checklist de Verificación**

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

### **2. Test de Funcionalidad**

```bash
# Crear namespace de prueba
kubectl create namespace cilium-test

# Crear deployment
kubectl create deployment nginx --image=nginx -n cilium-test

# Verificar conectividad
kubectl run test --image=busybox -n cilium-test --rm -it --restart=Never -- wget -q --timeout=5 nginx -O -

# Limpiar
kubectl delete namespace cilium-test
```

## 📊 **Monitoreo y Métricas**

### **1. Métricas de Cilium**

```bash
# Verificar métricas disponibles
cilium metrics list

# Ver métricas en tiempo real
cilium metrics list --json | jq '.[] | select(.name | contains("cilium"))'

# Ver métricas de endpoints
cilium endpoint list --verbose
```

### **2. Logs de Cilium**

```bash
# Ver logs en tiempo real
kubectl logs -n kube-system -l k8s-app=cilium -f

# Ver logs de Hubble
kubectl logs -n kube-system -l k8s-app=hubble-relay -f

# Ver logs del operador
kubectl logs -n kube-system -l name=cilium-operator -f
```

## 🔒 **Configuración de Seguridad**

### **1. Network Policies con Cilium**

```bash
# Crear namespace de prueba
kubectl create namespace cilium-test

# Crear deployment de prueba
kubectl create deployment nginx --image=nginx -n cilium-test

# Crear service
kubectl expose deployment nginx --port=80 -n cilium-test

# Verificar conectividad
kubectl run test-connectivity --image=busybox -n cilium-test --rm -it --restart=Never -- wget -q --timeout=5 nginx -O -
```

### **2. Configuración de Cilium Policies**

```bash
# Crear política de red básica
cat <<EOF | kubectl apply -f -
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: deny-all
  namespace: cilium-test
spec:
  endpointSelector: {}
  ingress:
  - {}
EOF

# Verificar política
kubectl get ciliumnetworkpolicies -n cilium-test
```

## 🚨 **Troubleshooting Común**

### **1. Problemas de k3s**

```bash
# Verificar logs de k3s
sudo journalctl -u k3s -f

# Verificar estado del servicio
sudo systemctl status k3s

# Reiniciar K3S si es necesario
sudo systemctl restart k3s

# Verificar configuración
sudo cat /etc/rancher/k3s/k3s.yaml
```

### **2. Problemas de Cilium**

```bash
# Verificar pods de Cilium
kubectl get pods -n kube-system -l k8s-app=cilium

# Verificar logs de Cilium
kubectl logs -n kube-system -l k8s-app=cilium --tail=100

# Verificar estado de Cilium
cilium status

# Reiniciar Cilium si es necesario
kubectl delete pods -n kube-system -l k8s-app=cilium
```

### **3. Problemas de Conectividad**

```bash
# Verificar endpoints de Cilium
cilium endpoint list

# Verificar políticas de red
cilium policy get

# Verificar conectividad
cilium connectivity test

# Verificar métricas
cilium metrics list
```

## 🔄 **Mantenimiento y Actualizaciones**

### **1. Actualización de K3S**

```bash
# Verificar versión actual
k3s --version

# Actualizar K3S
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.0+k3s1 sh -

# Verificar nueva versión
k3s --version
```

### **2. Actualización de Cilium**

```bash
# Verificar versión actual
cilium version

# Actualizar Cilium
helm repo update
helm upgrade cilium cilium/cilium -n kube-system

# Verificar nueva versión
cilium version
```

### **3. Backup de Configuración**

```bash
# Backup de configuración de K3S
sudo cp /etc/rancher/k3s/k3s.yaml ~/k3s-config-backup.yaml

# Backup de configuración de Cilium
helm get values cilium -n kube-system > ~/cilium-values-backup.yaml

# Backup de recursos de Kubernetes
kubectl get all --all-namespaces -o yaml > ~/k8s-resources-backup.yaml
```

## 📚 **Recursos Adicionales**

- [k3s Documentation](https://docs.k3s.io/)
- [Cilium Documentation](https://docs.cilium.io/)
- [eBPF Documentation](https://ebpf.io/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## 🤝 **Soporte**

Para problemas específicos:

1. Revisar logs de k3s y Cilium
2. Verificar estado del cluster
3. Consultar documentación oficial
4. Crear issue en el repositorio

---

### El cluster está listo para el siguiente paso: instalación de ArgoCD 🚀
