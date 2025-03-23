# Script de Configuración de Nginx con HTTPS

Este repositorio contiene un script para configurar fácilmente Nginx con HTTPS en servidores Ubuntu, especialmente útil para desplegar aplicaciones web.

## Características

- Instalación y configuración automática de Nginx
- Configuración de HTTPS mediante Certbot/Let's Encrypt
- Soporte para diferentes tipos de aplicaciones (Next.js, Express, Rust/Actix, etc.)
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

## Uso

1. Clone este repositorio en su servidor:

```bash
git clone https://github.com/tu-usuario/setup-server.git
cd setup-server
```

2. Haga el script ejecutable:

```bash
chmod +x setup-nginx.sh
```

3. Ejecute el script con privilegios sudo:

```bash
sudo ./setup-nginx.sh
```

4. Siga las instrucciones en pantalla para proporcionar:
   - Dominio (ejemplo.com)
   - Si desea incluir o no el subdominio www
   - Puerto donde se ejecuta su aplicación
   - Tipo de aplicación (Next.js, Express, Rust/Actix, o genérico)
   - Correo electrónico para los certificados SSL

## Mejoras recientes

El script ahora incluye:
- Validación de dominio y puerto
- Verificación de DNS antes de proceder con Certbot
- Detección de puertos ya en uso
- Opción para incluir o no el subdominio www
- Soporte completo para IPv6
- Configuración optimizada para diferentes tipos de aplicaciones

## Múltiples aplicaciones

Puede ejecutar el script varias veces para configurar múltiples aplicaciones en el mismo servidor. El script detectará automáticamente si Nginx y Certbot ya están instalados y solo configurará la nueva aplicación.

## Nota importante

Este script configura Nginx para proxy inverso a su aplicación, pero no gestiona la ejecución de su aplicación. Usted debe asegurarse de que su aplicación esté funcionando en el puerto especificado.