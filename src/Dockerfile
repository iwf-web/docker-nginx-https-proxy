ARG NGINX_VERSION=1.22

FROM iwfwebsolutions/nginx:${NGINX_VERSION}-latest

COPY ./nginx-config/proxy.conf /data/conf/nginx/framework-configs/proxy.conf

ENV APP_FRAMEWORK=proxy
