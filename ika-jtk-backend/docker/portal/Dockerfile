# syntax=docker/dockerfile:1.7
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://localhost:5000
RUN printf '{"API_BASE_URL":"%s"}\n' "$API_BASE_URL" > config/docker.json \
    && flutter build web --release --dart-define-from-file=config/docker.json

FROM nginx:1.27-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(?:css|js|woff2?|ttf|eot|svg|png|jpe?g|gif|webp|ico|wasm)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public";
    }
}
EOF
EXPOSE 80
