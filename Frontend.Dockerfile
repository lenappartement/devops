FROM httpd:2.4
COPY ./frontend/index.html /usr/local/apache2/htdocs/
COPY ./frontend/httpd.conf /usr/local/apache2/conf/httpd.conf