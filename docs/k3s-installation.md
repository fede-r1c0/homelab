# 🚀 k3s installation for Homelab Kubernetes

## 📋 **Descripción**

Esta guía detalla la instalación de k3s (Kubernetes ligero) en Raspberry Pi 5. El setup está optimizado para entornos de homelab con recursos limitados, proporcionando una base sólida para experimentar con tecnologías cloud-native.

## 🎯 **Objetivos del Setup**

- **Cluster Kubernetes funcional** en Raspberry Pi 5 o Linux arm64
- **CNI avanzado** con Cilium y eBPF
- **Base para GitOps** con ArgoCD
- **Entorno de aprendizaje** para DevOps y SRE

## 🛠️ **Prerrequisitos**

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

⚠️ Importante: Deshabilitaremos Network PolicyTraefik y Klipper para usar Cilium y MetalLB.

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

## 🔄 **3. Mantenimiento y Actualizaciones**

### **1. Actualización de K3S**

```bash
# Verificar versión actual
k3s --version

# Actualizar K3S
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.0+k3s1 sh -

# Verificar nueva versión
k3s --version
```
