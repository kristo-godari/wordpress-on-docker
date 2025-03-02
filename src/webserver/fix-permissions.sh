#!/bin/bash

chown -R nobody:nogroup "/var/www/vhosts/$DOMAIN_NAME/html/"
find "/var/www/vhosts/$DOMAIN_NAME/html/" -type f -exec chmod 664 {} +
find "/var/www/vhosts/$DOMAIN_NAME/html/" -type d -exec chmod 775 {} +
