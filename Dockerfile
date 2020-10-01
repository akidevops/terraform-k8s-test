FROM php:7.4.3-apache
COPY apache-conf/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY apache-conf/start-apache /usr/local/bin

# COPY APP Code.
COPY source/ /var/www/html/
RUN chown -R www-data:www-data /var/www/html/
CMD ["start-apache"]