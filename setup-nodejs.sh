#!/bin/bash

# Colores para mejor legibilidad
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con formato
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar si el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root (sudo)."
    exit 1
fi

# Función para verificar si un comando se ejecutó correctamente
check_result() {
    if [ $? -ne 0 ]; then
        print_error "$1"
        exit 1
    else
        print_success "$1"
    fi
}

# Actualizar el sistema
print_message "Actualizando lista de paquetes..."
apt update
check_result "Lista de paquetes actualizada correctamente."

# Instalar dependencias necesarias
print_message "Instalando dependencias necesarias..."
apt install -y curl
check_result "Dependencias instaladas correctamente."

# Instalar Node.js LTS
print_message "Instalando Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
check_result "Repositorio de Node.js configurado correctamente."

apt install -y nodejs
check_result "Node.js instalado correctamente."

# Verificar versión de Node.js y npm
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
print_success "Node.js ${NODE_VERSION} y npm ${NPM_VERSION} instalados correctamente."

# Instalar Yarn
print_message "Instalando Yarn..."
npm install -g yarn
check_result "Yarn instalado correctamente."

# Verificar versión de Yarn
YARN_VERSION=$(yarn -v)
print_success "Yarn ${YARN_VERSION} instalado correctamente."

# Instalar PM2
print_message "Instalando PM2..."
npm install -g pm2
check_result "PM2 instalado correctamente."

# Verificar versión de PM2
PM2_VERSION=$(pm2 -v)
print_success "PM2 ${PM2_VERSION} instalado correctamente."

# Configurar PM2 para iniciar en el arranque
print_message "Configurando PM2 para iniciar en el arranque..."
env PATH=$PATH:/usr/bin pm2 startup systemd -u $SUDO_USER --hp /home/$SUDO_USER
check_result "PM2 configurado para iniciar en el arranque."

print_success "¡Instalación completada!"
print_message "Node.js, Yarn y PM2 han sido instalados y configurados correctamente."
print_message "Para gestionar sus aplicaciones, use comandos como:"
echo -e "  ${YELLOW}pm2 start app.js${NC} - Iniciar una aplicación"
echo -e "  ${YELLOW}pm2 list${NC} - Listar aplicaciones en ejecución"
echo -e "  ${YELLOW}pm2 save${NC} - Guardar la lista actual de aplicaciones"
echo -e "  ${YELLOW}pm2 restart app_name${NC} - Reiniciar una aplicación"
echo -e "  ${YELLOW}pm2 stop app_name${NC} - Detener una aplicación"
echo -e "  ${YELLOW}pm2 logs${NC} - Ver logs de todas las aplicaciones"
echo -e "  ${YELLOW}pm2 logs app_name${NC} - Ver logs de una aplicación específica" 