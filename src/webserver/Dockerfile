FROM litespeedtech/openlitespeed:1.7.16-lsphp81

# define args
ARG ADMIN_USERNAME
ARG ADMIN_PASSWORD
ARG DOMAIN_NAME
ARG WORDPRESS_VERSION
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD
ARG DB_HOST
ARG AUTH_KEY
ARG SECURE_AUTH_KEY
ARG LOGGED_IN_KEY
ARG NONCE_KEY
ARG AUTH_SALT
ARG SECURE_AUTH_SALT
ARG LOGGED_IN_SALT
ARG NONCE_SALT
ARG SITE_URL

## Update ##
RUN apt-get update

## Configure VM ##
# install some usefull tools
RUN apt-get install net-tools systemctl nano -y

# installing sendmail
RUN apt-get install sendmail -y
# configuring sendmail using default configuration
RUN sendmailconfig
# enabling to start a deamon on port 25
RUN sed -i 's/^DAEMON_OPTIONS/dnl DAEMON_OPTIONS/' /etc/mail/sendmail.mc
# compile the sendmail config
RUN m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
# add host name to local host names
RUN sed -i "1 i\\$DOMAIN_NAME" /etc/mail/local-host-names
# make sendmail start when container starts
RUN update-rc.d sendmail enable
# restart send mail to apply all the above configurations
RUN /etc/init.d/sendmail restart

## Configure LiteSpeed ##
# change litespeed server username and password
RUN echo "$ADMIN_USERNAME:$(/usr/local/lsws/admin/fcgi-bin/admin_php -q /usr/local/lsws/admin/misc/htpasswd.php $ADMIN_PASSWORD)" > /usr/local/lsws/admin/conf/htpasswd
RUN mkdir -p "/usr/local/lsws/conf/vhosts/${DOMAIN_NAME}"
COPY webserver-config/httpd_config.conf "/usr/local/lsws/conf"
COPY webserver-config/mime.properties "/usr/local/lsws/conf"
COPY webserver-config/vhosts/site-name-dot-com/vhconf.conf "/usr/local/lsws/conf/vhosts/${DOMAIN_NAME}"

## Build website config ##
# Update httpd_config.conf with DOMAIN_NAME and SITE_URL
RUN sed -i.backup "s/site-name-dot-com/${DOMAIN_NAME}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s,placeholder-site-url,${SITE_URL},g" "/usr/local/lsws/conf/httpd_config.conf"
# Update httpd_config.conf with DB_NAME, DB_USER, DB_PASSWORD, DB_HOST
RUN sed -i.backup "s/placeholder-db-name/${DB_NAME}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-db-user/${DB_USER}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-db-passowrd/${DB_PASSWORD}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-db-host/${DB_HOST}/g" "/usr/local/lsws/conf/httpd_config.conf"
# Update httpd_config.conf with AUTH_KEY, SECURE_AUTH_KEY, LOGGED_IN_KEY, NONCE_KEY, AUTH_SALT, SECURE_AUTH_SALT, LOGGED_IN_SALT, NONCE_SALT
RUN sed -i.backup "s/placeholder-auth-key/${AUTH_KEY}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-secure-auth-key/${SECURE_AUTH_KEY}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-login-key/${LOGGED_IN_KEY}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-nonce-key/${NONCE_KEY}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-auth-salt/${AUTH_SALT}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-secure-auth-salt/${SECURE_AUTH_SALT}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-login-salt/${LOGGED_IN_SALT}/g" "/usr/local/lsws/conf/httpd_config.conf"
RUN sed -i.backup "s/placeholder-salt/${NONCE_SALT}/g" "/usr/local/lsws/conf/httpd_config.conf"

## Install WordPress ##
# Create the target directory if it doesn't exist
RUN mkdir -p "/var/www/vhosts/${DOMAIN_NAME}/html"

# Download WordPress
RUN curl -O "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"

# Extract files to the correct path
RUN tar -xzf "wordpress-${WORDPRESS_VERSION}.tar.gz" --strip-components=1 -C "/var/www/vhosts/${DOMAIN_NAME}/html"

# Remove the tarball to save space
RUN rm "wordpress-${WORDPRESS_VERSION}.tar.gz"

## Configure WordPress ##
# Copy .htaccess and wp-config.php to the WordPress directory
COPY website-files/.htaccess "/var/www/vhosts/${DOMAIN_NAME}/html"
COPY website-files/wp-config.php "/var/www/vhosts/${DOMAIN_NAME}/html"

COPY fix-permissions.sh /home/fix-permissions.sh