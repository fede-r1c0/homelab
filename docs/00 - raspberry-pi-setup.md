# 🍓 Raspberry Pi 5 setup for Homelab Kubernetes

## 📋 **Descripción**

Esta guía detalla la configuración completa de una Raspberry Pi 5 para funcionar como nodo único de Kubernetes en un entorno de homelab.  
El setup está optimizado para desarrollo, aprendizaje y experimentación con tecnologías cloud-native.

## 🎯 **Objetivos del Setup**

- **Entorno de desarrollo** para Kubernetes y tecnologías CNCF
- **Laboratorio de aprendizaje** para DevOps y SRE
- **Base sólida** para experimentar con GitOps y observabilidad
- **Portfolio profesional** demostrando habilidades enterprise-grade

## 🛠️ **Hardware**

### **Raspberry Pi 5**

- **RAM**: 8GB
- **CPU**: ARM64 2.4GHz quad-core
- **Almacenamiento**: 256GB M.2 NVMe SSD
- **Red**: Gigabit Ethernet
- **Enfriamiento**: Active Cooling Kit

### **Accesorios Adicionales**

- **Fuente de alimentación**: Official 27W 5V/3A USB-C Power Supply
- **Extensión de almacenamiento**: Pimoroni Base NVMe M.2
- **Memoria SD**: SD Card de 32GB o superior para instalar el sistema operativo.
- **Cable de red**: Cat6 o superior
- **Periféricos**: Monitor, teclado y mouse para configuración inicial
- **Extra cables**: Cable Micro HDMI a HDMI.

Instalación de Pimoroni Base NVMe: [https://learn.pimoroni.com/article/getting-started-with-nvme-base/](https://learn.pimoroni.com/article/getting-started-with-nvme-base)

## 🚀 **Preparación del Sistema Base**

### **1. Descarga de Raspberry Pi OS**

```bash
# Descargar Ubuntu Server 25.04 para Raspberry Pi
wget https://cdimage.ubuntu.com/releases/25.04/release/ubuntu-25.04-preinstalled-server-arm64+raspi.img.xz

# Verificar checksum
sha256sum ubuntu-25.04-preinstalled-server-arm64+raspi.img.xz
```

### **2. Flash de la MicroSD**

```bash
# Descomprimir imagen
xz -d ubuntu-25.04-preinstalled-server-arm64+raspi.img.xz

# Identificar dispositivo de la microSD
lsblk

# Flash de la imagen (reemplazar /dev/sdX con tu dispositivo)
sudo dd if=ubuntu-25.04-preinstalled-server-arm64+raspi.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### **3. Configuración Inicial**

```bash
# Montar la microSD
sudo mount /dev/sdX2 /mnt

# Configurar hostname
echo "homelab-k8s" | sudo tee /mnt/etc/hostname

# Configurar usuario inicial
sudo chroot /mnt passwd ubuntu

# Desmontar
sudo umount /mnt
```

## 🔧 **Primer Boot y Configuración**

### **1. Conexión Inicial**

```bash
# Conectar Raspberry Pi a la red
# Usar monitor y teclado para la primera configuración

# Login con usuario: ubuntu
# Cambiar contraseña en el primer boot
```

### **2. Configuración de Red**

```bash
# Verificar conectividad
ip addr show
ping -c 3 8.8.8.8

# Configurar IP estática (opcional)
sudo nano /etc/netplan/50-cloud-init.yaml
```

### **3. Actualización del Sistema**

```bash
# Actualizar paquetes del sistema
sudo apt update && sudo apt upgrade -y

# Instalar paquetes esenciales
sudo apt install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  tree \
  jq \
  unzip \
  htop \
  iotop \
  nethogs \
  tcpdump \
  net-tools \
  openssh-server
```

## 🔐 **Configuración SSH y Seguridad**

### **1. Configuración SSH**

```bash
# Habilitar SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# Verificar estado
sudo systemctl status ssh

# Configurar firewall básico
sudo ufw allow ssh
sudo ufw enable
```

### **2. Generación de Claves SSH**

```bash
# Generar clave SSH para GitHub
ssh-keygen -t ed25519 -C "xxxx@xxxx"

# Copiar clave pública
cat ~/.ssh/id_ed25519.pub

# Agregar a GitHub (Settings > SSH and GPG keys)
```

### **3. Configuración SSH Avanzada**

```bash
# Configurar SSH para mayor seguridad
sudo vi /etc/ssh/sshd_config

# Cambios recomendados:
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes
# Port 22 (o cambiar a puerto no estándar)

# Reiniciar SSH
sudo systemctl restart ssh
```

## 🐧 **Configuración del Entorno de Desarrollo**

### **1. Instalación de Herramientas de Desarrollo**

```bash
sudo apt update
sudo apt install -y zsh \
  apt-transport-https \
  iptables \
  fail2ban \
  git \
  neovim \
  fontconfig \
  jq \
  yq \
  tree \
  age \
  bat \
  fd-find \
  ripgrep \
  fzf \
  tldr \
  zoxide \
  btop \
  thefuck \
  pre-commit
```

Más herramientas como docker, kubernetes, fnm, pyenv, etc. se pueden instalar siguiendo la siguiente docuemntacion de mis dotfiles: [https://github.com/fede-r1c0/dotfiles/blob/main/zsh/README.md#raspberry-pi-os](https://github.com/fede-r1c0/dotfiles/blob/main/zsh/README.md#raspberry-pi-os)

### **2. Configuración de Git**

```bash
# Configurar Git global
git config --global user.name "user"
git config --global user.email "email"

# Configurar editor preferido
git config --global core.editor "vim"

# Configurar alias útiles
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
```

### **3. Configuración de Shell y Entorno**

**Recomendación:** Usa tu repositorio de dotfiles con GNU Stow

Si ya tienes configuraciones personalizadas para zsh, vim, etc. en tu repositorio de dotfiles, puedes clonarlo y aplicar la configuración fácilmente usando GNU Stow.
Si no, puedes usar el mío como referencia para crear el tuyo. [https://github.com/fede-r1c0/dotfiles/blob/main/zsh/README.md#raspberry-pi-os](https://github.com/fede-r1c0/dotfiles/blob/main/zsh/README.md#raspberry-pi-os)

```bash
# 1. Instala GNU Stow si no lo tienes:
sudo apt install -y stow

# 2. Clona tu repositorio de dotfiles (o el mio):
git clone https://github.com/fede-r1c0/dotfiles ~/dotfiles

# 3. Entra al directorio y aplica la configuración de zsh (y otras que quieras):
cd ~/dotfiles

stow zsh
# Puedes stowear otras configuraciones, por ejemplo:
# stow neovim

# 4. Reinicia la terminal o ejecuta `zsh` para cargar la nueva configuración.
```

Esto es más reproducible y portable que configurar todo desde cero.

👉 **Alternativa: Instalar y configurar Oh My Zsh manualmente**

Si prefieres no usar dotfiles, puedes seguir los pasos de instalación de Oh My Zsh y plugins como se describe abajo.

```bash
# Instalar Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Instalar plugins útiles
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configurar .zshrc
vi ~/.zshrc

# Agregar plugins:
# plugins=(git docker kubectl helm zsh-autosuggestions zsh-syntax-highlighting)
```

## 🔧 **Optimizaciones del Sistema**

### **1. Configuración de Cgroups**

```bash
# Habilitar cgroups para Kubernetes
echo 'cgroup_memory=1 cgroup_enable=memory' | sudo tee -a /boot/firmware/cmdline.txt

# Verificar configuración
cat /boot/firmware/cmdline.txt
```

### **2. Optimización de PCIe a PCIe 3**

El puerto PCIe de la Raspberry Pi 5 utiliza la especificación PCIe 1.0 por defecto. Sin embargo, puede funcionar a mayor velocidad, aunque esto no está oficialmente soportado y es algo experimental. Esta opción solo funciona en Raspberry Pi OS.

Para habilitar el modo 'PCIe 3', abre una terminal y ejecuta:

```bash
sudo vi /boot/firmware/config.txt
```

Agrega la siguiente línea en la sección [all] al final del archivo:

```text
dtparam=pciex1_gen=3
```

Referencia: [https://learn.pimoroni.com/article/getting-started-with-nvme-base#optional-and-unsupported-speed-increase](https://learn.pimoroni.com/article/getting-started-with-nvme-base#optional-and-unsupported-speed-increase)

Guarda el archivo y reiniciar el sistema operativo..

## 📊 **Monitoreo del Sistema**

### **1. Herramientas de Monitoreo**

```bash
# Instalar herramientas de monitoreo
sudo apt install -y \
  htop \
  iotop \
  nethogs \
  tcpdump \
  netstat-nat \
  sysstat

# Configurar sysstat para monitoreo continuo
sudo sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
sudo systemctl enable sysstat
sudo systemctl start sysstat
```

### **2. Logs del Sistema**

```bash
# Configurar rotación de logs
sudo vi /etc/logrotate.conf

# Ver logs en tiempo real
sudo journalctl -f

# Ver logs del sistema
sudo tail -f /var/log/syslog
```

## 🔍 **Verificación del Setup**

### **1. Checklist de Verificación**

```bash
# Verificar conectividad de red
ping -c 3 8.8.8.8
curl -I https://google.com

# Verificar SSH
ssh localhost

# Verificar herramientas instaladas
git --version
docker --version
go version
node --version
```

## 🚨 **Troubleshooting Común**

### **1. Problemas de Red**

```bash
# Verificar interfaces de red
ip addr show

# Verificar configuración DNS
cat /etc/resolv.conf

# Reiniciar servicios de red
sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-resolved
```

### **2. Problemas de SSH**

```bash
# Verificar estado del servicio
sudo systemctl status ssh

# Verificar logs
sudo journalctl -u ssh

# Verificar puerto
sudo netstat -tlnp | grep :22
```

### **3. Problemas de Rendimiento**

```bash
# Verificar uso de CPU y memoria
htop

# Verificar uso de disco
df -h

# Verificar temperatura
vcgencmd measure_temp
```

## 🔄 **Mantenimiento del Sistema**

### **1. Actualizaciones Regulares**

```bash
# Actualización semanal
sudo apt update && sudo apt upgrade -y

# Limpieza de paquetes
sudo apt autoremove -y
sudo apt autoclean
```

### **2. Backup de Configuración**

```bash
# Backup de archivos de configuración
tar -czf ~/system-config-backup-$(date +%Y%m%d).tar.gz \
  /etc/ssh/sshd_config \
  /etc/netplan/ \
  /boot/firmware/cmdline.txt \
  ~/.ssh/ \
  ~/.zshrc
```

### **3. Monitoreo de Salud**

```bash
# Verificar espacio en disco
df -h

# Verificar uso de memoria
free -h

# Verificar temperatura
vcgencmd measure_temp

# Verificar logs del sistema
sudo journalctl --since "1 hour ago" | grep -i error
```

## 📚 **Recursos Adicionales**

- [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [SSH Best Practices](https://www.ssh.com/academy/ssh/best-practices)

## 🤝 **Soporte**

Para problemas específicos:

1. Revisar logs del sistema
2. Verificar conectividad de red
3. Consultar documentación oficial
4. Crear issue en el repositorio
