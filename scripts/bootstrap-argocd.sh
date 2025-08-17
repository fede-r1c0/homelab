#!/bin/bash

# 🚀 ArgoCD Bootstrap - Homelab
# Este script automatiza la configuración completa de ArgoCD

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para detectar arquitectura
detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armv8l)
            echo "arm"
            ;;
        *)
            echo "amd64"  # fallback
            ;;
    esac
}

# Función para instalar kubectl
install_kubectl() {
    log_info "Verificando kubectl..."
    
    if command -v kubectl &> /dev/null; then
        log_success "kubectl ya está instalado"
        kubectl version --client
        return 0
    fi
    
    log_info "📥 Instalando kubectl..."
    
    local arch=$(detect_architecture)
    log_info "Arquitectura detectada: $arch"
    
    # Detectar sistema operativo
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        log_info "Instalando kubectl en Linux ($arch)..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$arch/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        log_info "Instalando kubectl en macOS..."
        if command -v brew &> /dev/null; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/$arch/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
        fi
    else
        log_error "Sistema operativo no soportado: $OSTYPE"
        log_info "📖 Instala kubectl manualmente desde: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        return 1
    fi
    
    # Verificar instalación
    if command -v kubectl &> /dev/null; then
        log_success "kubectl instalado exitosamente"
        kubectl version --client
    else
        log_error "Error al instalar kubectl"
        return 1
    fi
}

# Función para instalar ArgoCD CLI
install_argocd_cli() {
    log_info "Verificando ArgoCD CLI..."
    
    if command -v argocd &> /dev/null; then
        log_success "ArgoCD CLI ya está instalado"
        argocd version --client
        return 0
    fi
    
    log_info "📥 Instalando ArgoCD CLI..."
    
    local arch=$(detect_architecture)
    log_info "Arquitectura detectada: $arch"
    
    # Detectar sistema operativo
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            # Debian/Ubuntu
            log_info "Instalando en sistema Debian/Ubuntu ($arch)..."
            curl -sSL -o "argocd-linux-$arch" "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-$arch"
            sudo install -m 555 "argocd-linux-$arch" /usr/local/bin/argocd
            rm "argocd-linux-$arch"
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
            # RHEL/CentOS/Fedora
            log_info "Instalando en sistema RHEL/CentOS/Fedora ($arch)..."
            curl -sSL -o "argocd-linux-$arch" "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-$arch"
            sudo install -m 555 "argocd-linux-$arch" /usr/local/bin/argocd
            rm "argocd-linux-$arch"
        else
            log_error "Sistema Linux no soportado. Instala ArgoCD CLI manualmente."
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        log_info "Instalando en macOS ($arch)..."
        if command -v brew &> /dev/null; then
            brew install argocd
        else
            curl -sSL -o "argocd-darwin-$arch" "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-$arch"
            sudo install -m 555 "argocd-darwin-$arch" /usr/local/bin/argocd
            rm "argocd-darwin-$arch"
        fi
    else
        log_error "Sistema operativo no soportado: $OSTYPE"
        log_info "📖 Instala ArgoCD CLI manualmente desde: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
        return 1
    fi
    
    # Verificar instalación
    if command -v argocd &> /dev/null; then
        log_success "ArgoCD CLI instalado exitosamente"
        argocd version --client
    else
        log_error "Error al instalar ArgoCD CLI"
        return 1
    fi
}

# Verificar prerrequisitos
check_prerequisites() {
    log_info "Verificando prerrequisitos..."
    
    # Instalar kubectl si no está disponible
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl no está instalado, intentando instalarlo..."
        if ! install_kubectl; then
            log_error "No se pudo instalar kubectl. Instálalo manualmente."
            exit 1
        fi
    fi
    
    # Instalar ArgoCD CLI si no está disponible
    if ! command -v argocd &> /dev/null; then
        log_warning "ArgoCD CLI no está instalado, intentando instalarlo..."
        if ! install_argocd_cli; then
            log_error "No se pudo instalar ArgoCD CLI. Instálalo manualmente."
            exit 1
        fi
    fi
    
    # Verificar que el cluster esté funcionando
    if ! kubectl cluster-info &> /dev/null; then
        log_error "No se puede conectar al cluster Kubernetes"
        exit 1
    fi
    
    log_success "Prerrequisitos verificados"
}

# Verificar que ArgoCD esté funcionando
check_argocd() {
    log_info "Verificando estado de ArgoCD..."
    
    if ! kubectl get pods -n $ARGOCD_NAMESPACE -l app.kubernetes.io/name=argocd-server &> /dev/null; then
        log_error "ArgoCD no está instalado o no está funcionando en el namespace $ARGOCD_NAMESPACE"
        exit 1
    fi
    
    # Esperar a que ArgoCD esté listo
    log_info "Esperando a que ArgoCD esté listo..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n $ARGOCD_NAMESPACE --timeout=300s
    
    log_success "ArgoCD está funcionando correctamente"
}

# Función para obtener puertos del servicio ArgoCD
get_argocd_ports() {
    local http_port=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null)
    local https_port=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}' 2>/dev/null)
    
    echo "$http_port:$https_port"
}

# Configurar conexión de ArgoCD CLI
setup_argocd_connection() {
    log_info "Configurando conexión de ArgoCD CLI..."
    
    # Obtener puertos del servicio
    local ports=$(get_argocd_ports)
    local http_port=$(echo $ports | cut -d: -f1)
    local https_port=$(echo $ports | cut -d: -f2)
    
    log_info "Puertos detectados - HTTP: $http_port, HTTPS: $https_port"
    
    # Verificar si MetalLB está funcionando realmente
    local metallb_working=false
    if kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null | grep -q '^[0-9]'; then
        local lb_ip=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        
        log_info "Detectado LoadBalancer IP: $lb_ip, puerto HTTPS: $https_port"
        
        # Verificar si realmente responde en el puerto correcto (timeout de 5 segundos)
        if timeout 5 bash -c "</dev/tcp/$lb_ip/$https_port" 2>/dev/null; then
            metallb_working=true
            log_info "LoadBalancer está funcionando correctamente en puerto $https_port"
        else
            log_warning "LoadBalancer detectado pero no responde en puerto $https_port, usando port-forward"
        fi
    fi
    
    if [[ "$metallb_working" == true ]]; then
        # Si MetalLB está funcionando realmente
        local argocd_service=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        local https_port=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
        
        log_info "Conectando a ArgoCD via LoadBalancer: $argocd_service:$https_port"
        
        if argocd cluster add --insecure --server "$argocd_service:$https_port" $(kubectl config current-context); then
            log_success "Conexión a ArgoCD configurada exitosamente via LoadBalancer"
        else
            log_warning "Error al conectar via LoadBalancer, usando port-forward como fallback"
            metallb_working=false
        fi
    fi
    
    if [[ "$metallb_working" == false ]]; then
        # Usar port-forward como método principal o fallback
        log_info "Configurando port-forward para ArgoCD..."
        log_warning "Se abrirá un port-forward en background. Presiona Ctrl+C para detenerlo cuando termines."
        
        # Crear port-forward en background (usando puerto HTTP 80 interno)
        kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:80 &
        local port_forward_pid=$!
        
        # Esperar un momento para que el port-forward esté listo
        sleep 5
        
        # Verificar que el port-forward esté funcionando
        if ! timeout 5 bash -c "</dev/tcp/localhost/8080" 2>/dev/null; then
            log_error "Port-forward no está funcionando correctamente"
            kill $port_forward_pid 2>/dev/null || true
            exit 1
        fi
        
        log_info "Port-forward verificado y funcionando en localhost:8080"
        log_info "Mapeando puerto local 8080 → puerto interno 80 (NodePort: $http_port)"
        
        # Agregar el cluster local (usando HTTP, no HTTPS)
        if argocd cluster add --insecure --server "localhost:8080" $(kubectl config current-context); then
            log_success "Conexión a ArgoCD configurada exitosamente via port-forward"
            log_info "Port-forward ejecutándose en PID: $port_forward_pid"
            log_info "Para detener el port-forward: kill $port_forward_pid"
        else
            log_error "Error al configurar conexión a ArgoCD"
            kill $port_forward_pid 2>/dev/null || true
            exit 1
        fi
    fi
}

# Agregar repositorio a ArgoCD
add_repository() {
    log_info "Agregando repositorio $REPO_URL a ArgoCD..."
    
    # Verificar si el repositorio ya existe
    if argocd repo list | grep -q "$REPO_URL"; then
        log_warning "El repositorio ya existe, actualizando..."
        argocd repo rm "$REPO_URL" || true
    fi
    
    # Agregar repositorio
    if argocd repo add "$REPO_URL" --type git; then
        log_success "Repositorio agregado correctamente"
    else
        log_error "Error al agregar el repositorio"
        exit 1
    fi
}

# Crear aplicación bootstrap
create_bootstrap_app() {
    log_info "Creando aplicación bootstrap $BOOTSTRAP_APP_NAME..."
    
    # Verificar si la aplicación ya existe
    if argocd app get "$BOOTSTRAP_APP_NAME" &> /dev/null; then
        log_warning "La aplicación bootstrap ya existe, actualizando..."
        argocd app delete "$BOOTSTRAP_APP_NAME" --yes || true
    fi
    
    # Crear aplicación bootstrap
    if argocd app create "$BOOTSTRAP_APP_NAME" \
        --repo "$REPO_URL" \
        --path argocd \
        --dest-namespace "$ARGOCD_NAMESPACE" \
        --dest-server https://kubernetes.default.svc \
        --project default \
        --sync-policy automated \
        --auto-prune \
        --self-heal; then
        
        log_success "Aplicación bootstrap creada correctamente"
    else
        log_error "Error al crear la aplicación bootstrap"
        exit 1
    fi
}

# Sincronizar aplicación bootstrap
sync_bootstrap_app() {
    log_info "Sincronizando aplicación bootstrap..."
    
    if argocd app sync "$BOOTSTRAP_APP_NAME" --prune; then
        log_success "Aplicación bootstrap sincronizada correctamente"
    else
        log_error "Error al sincronizar la aplicación bootstrap"
        exit 1
    fi
}

# Verificar estado de las aplicaciones
check_applications() {
    log_info "Verificando estado de las aplicaciones..."
    
    # Esperar un poco para que ArgoCD procese todo
    sleep 10
    
    # Listar todas las aplicaciones
    log_info "Aplicaciones creadas:"
    argocd app list
    
    # Verificar estado de la aplicación bootstrap
    log_info "Estado de la aplicación bootstrap:"
    argocd app get "$BOOTSTRAP_APP_NAME"
}

# Función principal
main() {
    log_info "🚀 Iniciando bootstrap automático de ArgoCD para Homelab..."
    
    check_prerequisites
    check_argocd
    setup_argocd_connection
    add_repository
    create_bootstrap_app
    sync_bootstrap_app
    check_applications
    
    log_success "✅ Bootstrap de ArgoCD completado exitosamente!"
    log_info "🎯 ArgoCD ahora gestionará automáticamente todo tu homelab"
    log_info "🌐 Accede a la UI de ArgoCD para monitorear el despliegue"
}

# Ejecutar función principal
main "$@"
