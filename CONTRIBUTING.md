# Contributing to HomeLab

¡Gracias por tu interés en contribuir a HomeLab! 🚀

Este documento proporciona las directrices para contribuir al proyecto. Por favor, léelo completamente antes de enviar tu primera contribución.

## 📋 Tabla de Contenidos

- [¿Cómo Puedo Contribuir?](#cómo-puedo-contribuir)
- [Configuración del Entorno](#configuración-del-entorno)
- [Proceso de Contribución](#proceso-de-contribución)
- [Estándares de Código](#estándares-de-código)
- [Reportar Bugs](#reportar-bugs)
- [Solicitar Features](#solicitar-features)
- [Preguntas y Discusiones](#preguntas-y-discusiones)
- [Licencia](#licencia)


## 🎯 ¿Cómo Puedo Contribuir?

### Reportar Bugs
- Incluye pasos para reproducir el problema
- Adjunta logs y configuraciones relevantes
- Especifica tu entorno (OS, versión de Kubernetes, etc.)

### Solicitar Features
- Describe el caso de uso y beneficio
- Incluye ejemplos de implementación si es posible
- Considera si la feature se alinea con los objetivos del proyecto

### Mejorar Documentación
- Corrige errores o ambigüedades
- Agrega ejemplos y casos de uso
- Traduce documentación a otros idiomas
- Mejora la estructura y navegación

### Contribuir Código
- Implementa features solicitadas
- Corrige bugs reportados
- Mejora la calidad del código existente
- Agrega tests y validaciones

## 🛠️ Configuración del Entorno

### Prerrequisitos
- Kubernetes cluster (k3s recomendado)
- ArgoCD instalado y configurado
- Helm 3.x
- kubectl configurado
- Git

### Setup Local
```bash
# 1. Fork del repositorio
git clone https://github.com/TU_USUARIO/homelab.git
cd homelab

# 2. Agregar upstream
git remote add upstream https://github.com/fede-r1c0/homelab.git

# 3. Crear branch para tu feature
git checkout -b feature/nombre-de-tu-feature
```

### Validación Local
```bash
# Validar manifiestos Kubernetes
./scripts/quick-check.sh

# Validar políticas OPA
conftest verify --policy policies/opa/ --data .

# Validar sintaxis YAML
yamllint .
```

## 🔄 Proceso de Contribución

### 1. Preparar tu Contribución

- **Asegúrate** de que tu feature/fix esté alineado con los objetivos del proyecto
- **Revisa** issues existentes para evitar duplicados
- **Discute** cambios significativos en un issue antes de implementar

### 2. Desarrollo

- **Mantén** commits atómicos y lógicos
- **Sigue** los estándares de código establecidos
- **Agrega tests** cuando sea apropiado
- **Documenta** cambios significativos

### 3. Commit y Push

```bash
# Agregar cambios
git add .

# Commit con mensaje descriptivo
git commit -m "feat: agregar nueva aplicación de monitoreo:

- Implementa Prometheus Operator con configuración optimizada
- Agrega dashboards de Grafana predefinidos
- Incluye alertas para métricas críticas del cluster

Closes #123"

# Push a tu fork
git push origin feature/nombre-de-tu-feature
```

### 4. Pull Request

- **Usa** el template de PR proporcionado
- **Describe** claramente los cambios y su motivación
- **Incluye** capturas de pantalla para cambios de UI
- **Referencia** issues relacionados
- **Solicita review** de maintainers relevantes

## 📝 Estándares de Código

### Estructura de Commits
Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Tipos:**
- `feat`: Nueva feature
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Cambios de formato (no afectan funcionalidad)
- `refactor`: Refactorización de código
- `test`: Agregar o corregir tests
- `chore`: Cambios en build, config, etc.

### Estándares de Kubernetes
- **Usar** namespaces apropiados
- **Aplicar** labels estándar (`app`, `version`, `environment`)
- **Configurar** resource limits y requests
- **Implementar** health checks y readiness probes
- **Seguir** principios de least privilege

### Estándares de ArgoCD
- **Usar** syncPolicy.automated cuando sea apropiado
- **Configurar** retry policies para apps críticas
- **Implementar** health checks personalizados
- **Documentar** dependencias entre aplicaciones

### Estándares de Helm
- **Usar** versiones específicas de charts
- **Validar** values.yaml con helm lint
- **Documentar** parámetros personalizados
- **Probar** charts en diferentes entornos

## 🐛 Reportar Bugs

### Template de Issue
```markdown
## Descripción del Bug
Descripción clara y concisa del problema.

## Pasos para Reproducir
1. Ir a '...'
2. Hacer clic en '...'
3. Scroll hasta '...'
4. Ver error

## Comportamiento Esperado
Descripción de lo que debería pasar.

## Comportamiento Actual
Descripción de lo que realmente pasa.

## Entorno
- OS: [ej. Ubuntu 22.04]
- Kubernetes: [ej. v1.28.0]
- ArgoCD: [ej. v2.8.0]
- Hardware: [ej. Raspberry Pi 5, 8GB RAM]

## Logs y Configuración
Adjunta logs relevantes, configuraciones y capturas de pantalla.

## Información Adicional
Cualquier otra información que pueda ser útil.
```

## 🚀 Solicitar Features

### Template de Feature Request
```markdown
## Resumen
Descripción clara y concisa de la feature solicitada.

## Motivación
¿Por qué esta feature es útil? ¿Qué problema resuelve?

## Propuesta de Solución
Descripción de la solución propuesta.

## Alternativas Consideradas
Otras soluciones que consideraste.

## Impacto
- ¿Afecta a usuarios existentes?
- ¿Requiere cambios en la arquitectura?
- ¿Necesita nueva infraestructura?

## Criterios de Aceptación
Lista de criterios que deben cumplirse para aceptar la feature.
```

## 💬 Preguntas y Discusiones

### Para Preguntas Generales
- **Issues**: Para preguntas específicas sobre funcionalidad
- **Discussions**: Para debates sobre arquitectura y diseño
- **Wiki**: Para documentación colaborativa

### Para Discusiones Técnicas
- **Crear issue** con etiqueta `discussion`
- **Usar Discussions** para temas complejos
- **Mantener** conversaciones enfocadas y constructivas

## 📚 Recursos Adicionales

### Documentación
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/)
- [Helm Documentation](https://helm.sh/docs/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)

### Herramientas de Desarrollo
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/docs/helm/)
- [conftest](https://www.conftest.dev/)
- [yamllint](https://yamllint.readthedocs.io/)

## 🔒 Licencia

Al contribuir a este proyecto, aceptas que tu contribución será licenciada bajo los mismos términos que el proyecto: **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International Public License**.

### ¿Qué Significa Esto?
- **Tu contribución** será accesible para la comunidad
- **Otros podrán** usar y modificar tu trabajo
- **Se mantiene** la protección contra uso comercial
- **El espíritu Open Source** se preserva

## 🎉 ¡Gracias!

Cada contribución, por pequeña que sea, ayuda a hacer este proyecto mejor para toda la comunidad. 

---

**¿Listo para contribuir?** ¡Empieza por hacer fork del repositorio y explorar los [issues abiertos](https://github.com/fede-r1c0/homelab/issues)! 🚀
