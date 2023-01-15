FROM litespeedtech/openlitespeed:1.7.16-lsphp81

# define args
ARG ADMIN_USERNAME
ARG ADMIN_PASSWORD
ARG DOMAIN_NAME

RUN apt-get update

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

# change litespeed server username and password
RUN echo "$ADMIN_USERNAME:$(/usr/local/lsws/admin/fcgi-bin/admin_php -q /usr/local/lsws/admin/misc/htpasswd.php $ADMIN_PASSWORD)" > /usr/local/lsws/admin/conf/htpasswd

# copy files in container
COPY config /usr/local/lsws/conf
COPY cert /usr/local/lsws/cert
COPY sites /var/www/vhosts/

# add correct permissions
RUN chown -R nobody:nogroup "/var/www/vhosts/$DOMAIN_NAME/html/"
RUN find "/var/www/vhosts/$DOMAIN_NAME/html/" -type f -exec chmod 664 {} +
RUN find "/var/www/vhosts/$DOMAIN_NAME/html/" -type d -exec chmod 775 {} +