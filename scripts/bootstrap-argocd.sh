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

# Verificar prerrequisitos
check_prerequisites() {
    log_info "Verificando prerrequisitos..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl no está instalado"
        exit 1
    fi
    
    if ! command -v argocd &> /dev/null; then
        log_error "argocd CLI no está instalado"
        exit 1
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
