# nginx-brotli

Official `nginx:mainline` (Debian) image plus the Brotli module, built with the upstream
[docker-nginx/modules](https://github.com/nginx/docker-nginx/tree/master/modules) Dockerfile
(`ENABLED_MODULES=brotli`). There is no Dockerfile in this repo.

GitHub Actions builds (amd64) on push to `main` and manually, then pushes
`<user>/nginx-brotli:latest`, `:<nginx version>` and `:base-<digest>` to Docker Hub.
The daily run skips the build if a `base-<digest>` tag already exists for the current `nginx:mainline`.

## Setup

Add repository secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (a Docker Hub access token).

## Usage

The module is installed but **not loaded** by default. Load it in the main context of `nginx.conf`
(before any `http {}` block), then enable it.

### Option 1: mount your own nginx.conf

Create `nginx.conf`:

```
load_module modules/ngx_http_brotli_filter_module.so;
load_module modules/ngx_http_brotli_static_module.so;

worker_processes auto;
events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;

    brotli on;
    brotli_comp_level 6;
    brotli_types text/plain text/css application/javascript application/json image/svg+xml;

    server {
        listen 80;
        root /usr/share/nginx/html;
    }
}
```

Run it:

```
docker run --rm -p 8080:80 \
  -v $PWD/nginx.conf:/etc/nginx/nginx.conf:ro \
  <user>/nginx-brotli:latest
```

### Option 2: derive your own image

```dockerfile
FROM <user>/nginx-brotli:latest
RUN sed -i '1i load_module modules/ngx_http_brotli_filter_module.so;\nload_module modules/ngx_http_brotli_static_module.so;' /etc/nginx/nginx.conf
COPY brotli.conf /etc/nginx/conf.d/brotli.conf
```

where `brotli.conf` contains the `brotli on;` directives above (valid at `http` level, which `conf.d` is included into).

### Verify

```
docker run --rm -v $PWD/nginx.conf:/etc/nginx/nginx.conf:ro <user>/nginx-brotli:latest nginx -t
curl -sI -H 'Accept-Encoding: br' http://localhost:8080/ | grep -i content-encoding
```
