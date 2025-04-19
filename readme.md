# Script de Configuración de Nginx con HTTPS

Este repositorio contiene scripts para configurar fácilmente servidores web, instalando y configurando Nginx con HTTPS, Node.js, PM2, y automatizando el despliegue de aplicaciones.

## Scripts disponibles

1. **setup-nginx.sh** - Configura Nginx con HTTPS para aplicaciones web
2. **setup-nodejs.sh** - Instala Node.js, Yarn y PM2 para aplicaciones JavaScript
3. **deploy-app.sh** - Automatiza el despliegue de aplicaciones desde un repositorio Git

## Características

- Instalación y configuración automática de Nginx
- Configuración de HTTPS mediante Certbot/Let's Encrypt
- Soporte para diferentes tipos de aplicaciones (Next.js, Express, Rust/Actix, Rust/Axum, etc.)
- Detección de instalaciones previas (idempotente)
- Validación de entradas para evitar configuraciones incorrectas
- Configura el firewall (ufw) si está activo
- Soporte para IPv6
- Mensajes informativos con colores para mejor legibilidad
- Configuración de múltiples aplicaciones en un mismo servidor

## Requisitos

- Ubuntu (probado en Ubuntu 24.04)
- Acceso root o privilegios sudo
- Dominio configurado con registros DNS apuntando al servidor

## Preparación del servidor

Si está configurando un servidor nuevo, se recomienda actualizar el sistema e instalar Git primero:

```bash
# Actualizar lista de paquetes
sudo apt update

# Actualizar paquetes instalados
sudo apt upgrade -y

# Instalar actualizaciones de seguridad
sudo apt dist-upgrade -y

# Instalar Git si no está instalado
sudo apt-get install git -y
```

## Nota importante para AWS EC2

Si está utilizando una instancia de AWS EC2 (o servicios similares), debe asegurarse de que los puertos HTTP (80) y HTTPS (443) estén abiertos en su grupo de seguridad:

1. Vaya a la consola de AWS > EC2 > Grupos de seguridad
2. Seleccione el grupo de seguridad asociado a su instancia
3. Añada reglas de entrada para:
   - TCP puerto 80 desde cualquier lugar (0.0.0.0/0 y ::/0 para IPv6)
   - TCP puerto 443 desde cualquier lugar (0.0.0.0/0 y ::/0 para IPv6)

**⚠️ Importante**: Si estos puertos no están abiertos, Certbot no podrá verificar su dominio y fallará al generar los certificados SSL.

## Uso de setup-nginx.sh

1. Clone este repositorio en su servidor:

```bash
git clone https://github.com/Mandy9943/setup-nginx
cd setup-nginx
```

2. Haga los scripts ejecutables:

```bash
chmod +x setup-nginx.sh setup-nodejs.sh deploy-app.sh
```

3. Ejecute el script con privilegios sudo:

```bash
sudo ./setup-nginx.sh
```

4. Siga las instrucciones en pantalla para proporcionar:
   - Dominio (ejemplo.com)
   - Si desea incluir o no el subdominio www
   - Puerto donde se ejecuta su aplicación
   - Tipo de aplicación (Next.js, Express, Rust/Actix, Rust/Axum, o genérico)
   - Correo electrónico para los certificados SSL

## Uso de setup-nodejs.sh

Este script instala Node.js LTS, Yarn y PM2, configurando todo lo necesario para ejecutar aplicaciones JavaScript.

### Instalación

```bash
sudo ./setup-nodejs.sh
```

### Características

- Instala Node.js en su versión LTS
- Instala Yarn como gestor de paquetes alternativo
- Instala PM2 para gestionar procesos de Node.js
- Configura PM2 para iniciar automáticamente en el arranque del sistema
- Muestra información útil sobre comandos básicos de PM2

## Uso de deploy-app.sh

Este script automatiza el despliegue completo de aplicaciones, incluyendo la clonación del repositorio, configuración de variables de entorno, instalación de dependencias y arranque con PM2.

### Uso básico

```bash
./deploy-app.sh <URL_REPO> <DIRECTORIO> <COMANDO_INICIO> [VARIABLES_ENV...]
```

### Ejemplo

```bash
./deploy-app.sh https://github.com/usuario/mi-proyecto.git mi-app "npm run start:prod" "PORT=3000" "DB_URL=mongodb://localhost"
```

### Características

- Clona un repositorio Git en la carpeta especificada
- Crea automáticamente un archivo .env con las variables proporcionadas
- Detecta si debe usar npm o yarn para instalar dependencias
- Inicia la aplicación con PM2 usando el comando especificado
- Gestiona actualizaciones si la aplicación ya estaba desplegada
- Configura PM2 para mantener la aplicación activa entre reinicios

## Mejoras recientes

El script ahora incluye:
- Validación de dominio y puerto
- Verificación de DNS antes de proceder con Certbot
- Detección de puertos ya en uso
- Opción para incluir o no el subdominio www
- Soporte completo para IPv6
- Configuración optimizada para diferentes tipos de aplicaciones
- **Nuevo**: Soporte para aplicaciones Rust/Axum con optimización para procesamiento de imágenes

## Configuraciones específicas

### Rust/Axum para procesamiento de imágenes
La configuración para Rust/Axum está optimizada para aplicaciones que realizan procesamiento intensivo como la manipulación de imágenes. Incluye:
- Tamaño máximo de carga de 100MB
- Tiempos de espera extendidos (300s)
- Buffering desactivado para mejor rendimiento con streams
- Configuración optimizada para WebSockets

## Múltiples aplicaciones

Puede ejecutar el script varias veces para configurar múltiples aplicaciones en el mismo servidor. El script detectará automáticamente si Nginx y Certbot ya están instalados y solo configurará la nueva aplicación.

## Nota importante

Este script configura Nginx para proxy inverso a su aplicación, pero no gestiona la ejecución de su aplicación. Para una gestión completa del despliegue, utilice una combinación de los tres scripts incluidos en este repositorio:

1. Primero use `setup-nodejs.sh` para instalar las dependencias necesarias
2. Luego use `deploy-app.sh` para desplegar su aplicación
3. Finalmente use `setup-nginx.sh` para configurar Nginx como proxy inverso

Esto le proporcionará un flujo de trabajo completo para desplegar aplicaciones web modernas.
