#!/bin/sh
# Substitution de la variable BACKEND_URL dans config.js
BACKEND_URL=${BACKEND_URL:-http://localhost:8000}
envsubst '${BACKEND_URL}' < /usr/share/nginx/html/config.template.js > /usr/share/nginx/html/config.js
nginx -g 'daemon off;'
