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

# Función para validar el dominio
validate_domain() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Función para validar el puerto
validate_port() {
    if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 1 ] || [ "$1" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Función para verificar si un puerto está en uso
check_port_in_use() {
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$1 "; then
            return 0 # Puerto en uso
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$1 "; then
            return 0 # Puerto en uso
        fi
    fi
    return 1 # Puerto libre
}

# Solicitar información necesaria
while true; do
    read -p "Ingrese el dominio (ej: ejemplo.com): " DOMAIN
    if validate_domain "$DOMAIN"; then
        break
    else
        print_error "Dominio no válido. Por favor, ingrese un dominio válido."
    fi
done

# Preguntar si desea incluir www
read -p "¿Desea incluir www.$DOMAIN también? (s/n): " INCLUDE_WWW
INCLUDE_WWW=$(echo "$INCLUDE_WWW" | tr '[:upper:]' '[:lower:]')

while true; do
    read -p "Ingrese el puerto donde se ejecuta la aplicación: " PORT
    if validate_port "$PORT"; then
        if check_port_in_use "$PORT"; then
            print_warning "El puerto $PORT ya está en uso. Asegúrese de que su aplicación esté configurada correctamente."
        fi
        break
    else
        print_error "Puerto no válido. Debe ser un número entre 1 y 65535."
    fi
done

read -p "Ingrese su correo electrónico (para certificados SSL): " EMAIL

# Menú para seleccionar el tipo de aplicación
echo "Seleccione el tipo de aplicación:"
echo "1) Next.js"
echo "2) Express (Node.js)"
echo "3) Rust (Actix)"
echo "4) Aplicación web genérica"
read -p "Opción (1-4): " APP_TYPE

# Verificar si Nginx ya está instalado
if ! command -v nginx &> /dev/null; then
    print_message "Nginx no está instalado. Instalando..."
    apt update
    apt install -y nginx
    print_success "Nginx instalado correctamente."
else
    print_message "Nginx ya está instalado."
fi

# Verificar si Certbot ya está instalado
if ! command -v certbot &> /dev/null; then
    print_message "Certbot no está instalado. Instalando..."
    apt install -y certbot python3-certbot-nginx
    print_success "Certbot instalado correctamente."
else
    print_message "Certbot ya está instalado."
fi

# Crear configuración de Nginx según el tipo de aplicación
CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"

DOMAIN_CONFIG=""
if [[ "$INCLUDE_WWW" == "s" ]]; then
    DOMAIN_CONFIG="$DOMAIN www.$DOMAIN"
else
    DOMAIN_CONFIG="$DOMAIN"
fi

case $APP_TYPE in
    1) # Next.js
        print_message "Configurando para Next.js..."
        cat > "$CONFIG_PATH" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_CONFIG;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
}
EOF
        ;;
    2) # Express
        print_message "Configurando para Express (Node.js)..."
        cat > "$CONFIG_PATH" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_CONFIG;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ;;
    3) # Rust/Actix
        print_message "Configurando para Rust (Actix)..."
        cat > "$CONFIG_PATH" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_CONFIG;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ;;
    4) # Genérico
        print_message "Configurando para aplicación web genérica..."
        cat > "$CONFIG_PATH" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_CONFIG;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ;;
    *)
        print_error "Opción no válida. Usando configuración genérica."
        cat > "$CONFIG_PATH" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_CONFIG;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ;;
esac

# Crear enlace simbólico para habilitar el sitio
if [ ! -f "/etc/nginx/sites-enabled/$DOMAIN" ]; then
    ln -s "$CONFIG_PATH" "/etc/nginx/sites-enabled/"
    print_success "Configuración de Nginx creada y habilitada."
else
    print_warning "La configuración ya estaba habilitada. Se ha actualizado."
fi

# Verificar la configuración de Nginx
nginx -t
if [ $? -ne 0 ]; then
    print_error "La configuración de Nginx tiene errores. Por favor, revise manualmente."
    exit 1
fi

# Reiniciar Nginx
systemctl restart nginx
print_success "Nginx reiniciado correctamente."

# Verificar resolvedor DNS para el dominio
print_message "Verificando resolución DNS para $DOMAIN..."
if ! host "$DOMAIN" &>/dev/null; then
    print_warning "No se puede resolver el dominio $DOMAIN. Es posible que los registros DNS no estén configurados correctamente."
    read -p "¿Desea continuar con la configuración de HTTPS? (s/n): " CONTINUE_HTTPS
    CONTINUE_HTTPS=$(echo "$CONTINUE_HTTPS" | tr '[:upper:]' '[:lower:]')
    if [[ "$CONTINUE_HTTPS" != "s" ]]; then
        print_message "Configuración de HTTPS omitida. Vuelva a ejecutar el script cuando los registros DNS estén configurados."
        exit 0
    fi
fi

# Configurar Certbot para HTTPS
print_message "Configurando HTTPS con Certbot..."
CERTBOT_DOMAINS=""
if [[ "$INCLUDE_WWW" == "s" ]]; then
    CERTBOT_DOMAINS="-d $DOMAIN -d www.$DOMAIN"
else
    CERTBOT_DOMAINS="-d $DOMAIN"
fi

certbot --nginx --non-interactive --agree-tos --email "$EMAIL" $CERTBOT_DOMAINS

if [ $? -ne 0 ]; then
    print_error "Hubo un problema al configurar HTTPS. Verifique manualmente."
    exit 1
fi

print_success "¡Configuración completada!"
print_message "Su aplicación ahora está disponible en: https://$DOMAIN"
print_message "Asegúrese de que su aplicación esté ejecutándose en el puerto $PORT"

# Verificar si el firewall está habilitado y configurar si es necesario
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        print_message "Configurando firewall (ufw)..."
        ufw allow 'Nginx Full'
        print_success "Firewall configurado para permitir tráfico HTTP/HTTPS."
    fi
fi

# Mostrar información sobre la renovación automática de certificados
print_message "Los certificados SSL se renovarán automáticamente mediante un cron job de Certbot."
print_message "Puede verificar la configuración de renovación con: systemctl status certbot.timer" 