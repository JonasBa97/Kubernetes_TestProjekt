# Docker image for Apache HTTP Server Project
FROM httpd:latest
# Copy files to webdirectory of Apache
COPY ./template_lugx_gaming/ /usr/local/apache2/htdocs/
# Expose Port 80 (standard http)
EXPOSE 80