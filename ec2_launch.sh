
#!/bin/bash

# Obtener la IP pública del equipo
# PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
PUBLIC_IP="wordpress-lb-252088356.us-east-1.elb.amazonaws.com"

# Ruta del archivo wp-config.php
WP_CONFIG_FILE="/var/www/html/wp-config.php"

# Verificar si el archivo existe
if [ -f "$WP_CONFIG_FILE" ]; then
    # Reemplazar MY-IP con la IP pública
    sudo sed -i "s|define('WP_HOME','https://MY-IP');|define('WP_HOME','https://$PUBLIC_IP');|g" "$WP_CONFIG_FILE"
    sudo sed -i "s|define('WP_SITEURL','https://MY-IP');|define('WP_SITEURL','https://$PUBLIC_IP');|g" "$WP_CONFIG_FILE"
    echo "IP pública reemplazada correctamente en $WP_CONFIG_FILE"
else
    echo "El archivo $WP_CONFIG_FILE no existe."
fi

sudo systemctl stop httpd
sudo systemctl start httpd