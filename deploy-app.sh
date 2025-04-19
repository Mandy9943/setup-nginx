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

# Verificar si PM2 está instalado
if ! command -v pm2 &> /dev/null; then
    print_error "PM2 no está instalado. Por favor, instale primero PM2 con 'sudo npm install -g pm2'."
    exit 1
fi

# Verificar si git está instalado
if ! command -v git &> /dev/null; then
    print_error "Git no está instalado. Por favor, instale primero Git con 'sudo apt install git'."
    exit 1
fi

# Mostrar ayuda si no se proporcionan argumentos
if [ $# -eq 0 ]; then
    print_message "Uso: $0 <URL_GIT> <DIRECTORIO> <COMANDO_INICIO> [VARIABLES_ENV...]"
    print_message "Ejemplo: $0 https://github.com/usuario/repo.git mi-app 'npm run start:prod' 'PORT=3000' 'DB_URL=mongodb://localhost'"
    exit 1
fi

# Obtener parámetros
GIT_URL=$1
APP_DIR=$2
START_COMMAND=$3
shift 3  # Quitar los primeros 3 argumentos para dejar solo las variables de entorno

# Validar la URL de Git
if [[ ! "$GIT_URL" =~ ^https?://.*\.git$ ]]; then
    print_warning "La URL de Git no parece tener el formato correcto. Asegúrese de que termine en .git"
    read -p "¿Desea continuar de todos modos? (s/n): " CONTINUE
    if [[ "$CONTINUE" != "s" ]]; then
        exit 1
    fi
fi

# Clonar el repositorio
print_message "Clonando el repositorio desde $GIT_URL en $APP_DIR..."
if [ -d "$APP_DIR" ]; then
    print_warning "El directorio $APP_DIR ya existe."
    read -p "¿Desea eliminarlo y volver a clonar? (s/n): " OVERWRITE
    if [[ "$OVERWRITE" == "s" ]]; then
        rm -rf "$APP_DIR"
    else
        print_message "Actualizando el repositorio existente..."
        cd "$APP_DIR"
        git pull
        cd ..
    fi
fi

if [ ! -d "$APP_DIR" ]; then
    git clone "$GIT_URL" "$APP_DIR"
    if [ $? -ne 0 ]; then
        print_error "Error al clonar el repositorio. Verifique la URL y sus permisos."
        exit 1
    fi
    print_success "Repositorio clonado correctamente."
fi

# Cambiar al directorio de la aplicación
cd "$APP_DIR"

# Crear archivo .env con las variables proporcionadas
if [ $# -gt 0 ]; then
    print_message "Creando archivo .env..."
    echo "# Archivo de configuración generado automáticamente" > .env
    echo "# Generado el: $(date)" >> .env
    echo "" >> .env
    
    for var in "$@"; do
        echo "$var" >> .env
    done
    
    print_success "Archivo .env creado correctamente."
fi

# Instalar dependencias
print_message "Instalando dependencias..."
if [ -f "yarn.lock" ]; then
    yarn install
    if [ $? -ne 0 ]; then
        print_error "Error al instalar dependencias con Yarn."
        exit 1
    fi
elif [ -f "package.json" ]; then
    npm install
    if [ $? -ne 0 ]; then
        print_error "Error al instalar dependencias con NPM."
        exit 1
    fi
else
    print_warning "No se encontró package.json. Omitiendo instalación de dependencias."
fi

# Configurar y arrancar la aplicación con PM2
print_message "Configurando la aplicación con PM2..."
APP_NAME=$(basename "$APP_DIR")

# Detener la instancia anterior si existe
pm2 stop "$APP_NAME" 2>/dev/null
pm2 delete "$APP_NAME" 2>/dev/null

print_message "Iniciando la aplicación con PM2 usando el comando: $START_COMMAND"
eval "pm2 start --name $APP_NAME \"$START_COMMAND\""

if [ $? -ne 0 ]; then
    print_error "Error al iniciar la aplicación con PM2."
    exit 1
fi

# Guardar la configuración de PM2
print_message "Guardando la configuración de PM2..."
pm2 save

print_success "¡Despliegue completado!"
print_message "La aplicación está ahora en ejecución con PM2."
print_message "Use los siguientes comandos para gestionar su aplicación:"
echo -e "  ${YELLOW}pm2 status${NC} - Ver estado de las aplicaciones"
echo -e "  ${YELLOW}pm2 logs $APP_NAME${NC} - Ver logs de la aplicación"
echo -e "  ${YELLOW}pm2 restart $APP_NAME${NC} - Reiniciar la aplicación"
echo -e "  ${YELLOW}pm2 stop $APP_NAME${NC} - Detener la aplicación"
echo
print_message "Directorio de la aplicación: $(pwd)" 