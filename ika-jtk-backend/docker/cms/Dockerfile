# syntax=docker/dockerfile:1.7
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html/admin
COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location = / {
        return 302 /admin/;
    }

    location /admin/ {
        try_files $uri $uri/ /admin/index.html;
    }

    location ~* \.(?:css|js|woff2?|ttf|eot|svg|png|jpe?g|gif|webp|ico)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public";
    }
}
EOF
EXPOSE 80
