FROM nginx:latest

RUN rm -rf /usr/share/nginx/html/*

COPY index.html /usr/share/nginx/html/
COPY todo.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
COPY script.js /usr/share/nginx/html/
COPY todo.js /usr/share/nginx/html/
COPY script.js /usr/share/nginx/html/

COPY default.conf /etc/nginx/conf.d/default.conf

COPY wizexercise.txt /usr/share/nginx/html/

EXPOSE 80
