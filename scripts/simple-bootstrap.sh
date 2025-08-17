#!/bin/bash

set -euo pipefail

# Configuración
REPO_URL="https://github.com/fede-r1c0/homelab"
ARGOCD_NAMESPACE="argocd"
BOOTSTRAP_APP_NAME="homelab-bootstrap"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar prerrequisitos básicos
check_prerequisites() {
    log_info "Verificando prerrequisitos básicos..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl no está instalado"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "No se puede conectar al cluster Kubernetes"
        exit 1
    fi
    
    if ! kubectl get pods -n $ARGOCD_NAMESPACE &> /dev/null; then
        log_error "ArgoCD no está instalado en el namespace $ARGOCD_NAMESPACE"
        exit 1
    fi
    
    log_success "Prerrequisitos verificados"
}

# Instalar ArgoCD CLI si no existe
install_argocd_cli() {
    if command -v argocd &> /dev/null; then
        log_info "ArgoCD CLI ya está instalado"
        return 0
    fi
    
    log_info "Instalando ArgoCD CLI..."
    
    local version="v3.1.0"
    local arch
    case $(uname -m) in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="arm" ;;
        *) log_error "Arquitectura no soportada: $(uname -m)"; exit 1 ;;
    esac
    
    local url="https://github.com/argoproj/argo-cd/releases/download/${version}/argocd-linux-${arch}"
    
    if curl -L "$url" -o /tmp/argocd && chmod +x /tmp/argocd; then
        sudo mv /tmp/argocd /usr/local/bin/argocd
        log_success "ArgoCD CLI instalado exitosamente"
    else
        log_error "Error al descargar ArgoCD CLI"
        exit 1
    fi
}

# Configurar ArgoCD CLI - MÉTODO SIMPLE
setup_argocd_cli() {
    log_info "Configurando ArgoCD CLI..."
    
    # Port-forward al servicio en el puerto CORRECTO
    log_info "Creando port-forward al servicio ArgoCD..."
    
    # El truco: usar el puerto 8080 local que mapea al targetPort 8080 del servicio
    local local_port=8080
    log_info "Port-forward: localhost:$local_port -> svc/argocd-server:80 (que mapea a targetPort:8080)"
    
    kubectl port-forward -n $ARGOCD_NAMESPACE svc/argocd-server $local_port:80 &
    local pf_pid=$!
    
    # Esperar que el port-forward esté listo
    sleep 5
    
    # Verificar que funciona
    if ! curl -k -s http://localhost:$local_port > /dev/null; then
        log_error "Port-forward no funciona en localhost:$local_port"
        kill $pf_pid 2>/dev/null || true
        exit 1
    fi
    
    log_success "Port-forward funcionando en localhost:$local_port"
    
    # Configurar ArgoCD CLI
    log_info "Configurando contexto de ArgoCD CLI..."
    
    if argocd cluster add --insecure --yes --upsert --server "localhost:$local_port" $(kubectl config current-context); then
        log_success "ArgoCD CLI configurado exitosamente"
        echo "PID del port-forward: $pf_pid"
        echo "Para detener: kill $pf_pid"
    else
        log_error "Error al configurar ArgoCD CLI"
        kill $pf_pid 2>/dev/null || true
        exit 1
    fi
}

# Agregar repositorio
add_repository() {
    log_info "Agregando repositorio GitHub..."
    
    if argocd repo add $REPO_URL --insecure --yes; then
        log_success "Repositorio agregado: $REPO_URL"
    else
        log_warning "El repositorio ya existe o hubo un error (continuando...)"
    fi
}

# Crear aplicación bootstrap
create_bootstrap_app() {
    log_info "Creando aplicación bootstrap..."
    
    if argocd app create $BOOTSTRAP_APP_NAME \
        --repo $REPO_URL \
        --path argocd/applications \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace default \
        --sync-policy automated \
        --auto-prune \
        --self-heal \
        --insecure \
        --upsert; then
        log_success "Aplicación bootstrap creada: $BOOTSTRAP_APP_NAME"
    else
        log_error "Error al crear aplicación bootstrap"
        exit 1
    fi
}

# Sincronizar aplicación
sync_application() {
    log_info "Sincronizando aplicación bootstrap..."
    
    if argocd app sync $BOOTSTRAP_APP_NAME --insecure; then
        log_success "Aplicación sincronizada exitosamente"
    else
        log_warning "Error en la sincronización (verificar manualmente)"
    fi
}

# Función principal
main() {
    log_info "🚀 Bootstrap de ArgoCD"
    echo "==============================================="
    
    check_prerequisites
    install_argocd_cli
    setup_argocd_cli
    add_repository
    create_bootstrap_app
    sync_application
    
    log_success "✅ Bootstrap completado exitosamente!"
    log_info "Accede a ArgoCD UI: http://192.168.68.100"
    log_info "Usuario: admin"
    log_info "Contraseña: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
}

# Ejecutar
main "$@"
