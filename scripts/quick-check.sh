#!/bin/bash

# 🔍 Verificación Rápida del Estado del Homelab
# Script para verificar rápidamente el estado del cluster y ArgoCD

set -euo pipefail

# Cargar configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

# Colores para output
if [[ "$ENABLE_COLORS" == "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

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

# Verificar conectividad al cluster
check_cluster() {
    log_info "🔍 Verificando conectividad al cluster..."
    
    if kubectl cluster-info &> /dev/null; then
        log_success "✅ Cluster accesible"
        kubectl cluster-info | head -1
    else
        log_error "❌ No se puede conectar al cluster"
        return 1
    fi
}

# Verificar nodos
check_nodes() {
    log_info "📊 Verificando nodos del cluster..."
    
    local node_count=$(kubectl get nodes --no-headers | wc -l)
    local ready_count=$(kubectl get nodes --no-headers | grep -c "Ready")
    
    if [[ $ready_count -eq $node_count ]]; then
        log_success "✅ Todos los nodos están listos ($ready_count/$node_count)"
    else
        log_warning "⚠️  Algunos nodos no están listos ($ready_count/$node_count)"
    fi
    
    kubectl get nodes -o wide
}

# Verificar ArgoCD
check_argocd() {
    log_info "🚀 Verificando estado de ArgoCD..."
    
    if kubectl get namespace $ARGOCD_NAMESPACE &> /dev/null; then
        log_success "✅ Namespace $ARGOCD_NAMESPACE existe"
    else
        log_error "❌ Namespace $ARGOCD_NAMESPACE no existe"
        return 1
    fi
    
    # Verificar pods de ArgoCD
    local argocd_pods=$(kubectl get pods -n $ARGOCD_NAMESPACE --no-headers | wc -l)
    local ready_pods=$(kubectl get pods -n $ARGOCD_NAMESPACE --no-headers | grep -c "Running\|Completed")
    
    if [[ $ready_pods -eq $argocd_pods ]]; then
        log_success "✅ Todos los pods de ArgoCD están listos ($ready_pods/$argocd_pods)"
    else
        log_warning "⚠️  Algunos pods de ArgoCD no están listos ($ready_pods/$argocd_pods)"
    fi
    
    kubectl get pods -n $ARGOCD_NAMESPACE
}

# Verificar aplicaciones
check_applications() {
    log_info "📱 Verificando aplicaciones de ArgoCD..."
    
    if kubectl get applications -n $ARGOCD_NAMESPACE &> /dev/null; then
        local app_count=$(kubectl get applications -n $ARGOCD_NAMESPACE --no-headers | wc -l)
        local synced_count=$(kubectl get applications -n $ARGOCD_NAMESPACE --no-headers | grep -c "Synced")
        
        if [[ $synced_count -eq $app_count ]]; then
            log_success "✅ Todas las aplicaciones están sincronizadas ($synced_count/$app_count)"
        else
            log_warning "⚠️  Algunas aplicaciones no están sincronizadas ($synced_count/$app_count)"
        fi
        
        kubectl get applications -n $ARGOCD_NAMESPACE
    else
        log_warning "⚠️  No hay aplicaciones configuradas aún"
    fi
}

# Verificar servicios
check_services() {
    log_info "🌐 Verificando servicios expuestos..."
    
    kubectl get svc -n $ARGOCD_NAMESPACE
    echo ""
    
    # Verificar servicios LoadBalancer
    local lb_services=$(kubectl get svc --all-namespaces -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}/{.metadata.name}:{.status.loadBalancer.ingress[0].ip}{"\n"}{end}' 2>/dev/null || true)
    
    if [[ -n "$lb_services" ]]; then
        log_info "🔗 Servicios LoadBalancer disponibles:"
        echo "$lb_services"
    else
        log_warning "⚠️  No hay servicios LoadBalancer configurados"
    fi
}

# Verificar recursos del sistema
check_resources() {
    log_info "💾 Verificando recursos del sistema..."
    
    # Memoria
    local memory_usage=$(free -h | grep "Mem:" | awk '{print $3"/"$2}')
    log_info "Memoria: $memory_usage"
    
    # Disco
    local disk_usage=$(df -h / | tail -1 | awk '{print $3"/"$2}')
    log_info "Disco: $disk_usage"
    
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    log_info "CPU: ${cpu_usage}%"
}

# Función principal
main() {
    echo -e "${BLUE}🔍 Verificación Rápida del Homelab Kubernetes${NC}"
    echo "=================================================="
    echo ""
    
    check_cluster
    echo ""
    
    check_nodes
    echo ""
    
    check_argocd
    echo ""
    
    check_applications
    echo ""
    
    check_services
    echo ""
    
    check_resources
    echo ""
    
    echo -e "${GREEN}✅ Verificación completada${NC}"
    echo ""
    echo -e "${BLUE}📋 Comandos útiles:${NC}"
    echo "  kubectl get pods --all-namespaces    # Ver todos los pods"
    echo "  kubectl get applications -n argocd   # Ver aplicaciones"
    echo "  kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server  # Ver logs de ArgoCD"
}

# Ejecutar función principal
main "$@"
