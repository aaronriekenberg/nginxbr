# nginx-brotli

Official `nginx:mainline` (Debian) image plus the Brotli module, built from
[pkg-oss](https://github.com/nginx/pkg-oss) following
[docker-nginx/modules](https://github.com/nginx/docker-nginx/tree/master/modules).

GitHub Actions builds (amd64 + arm64) on push to `main`, daily, and manually, then pushes
`<user>/nginx-brotli:latest` and `<user>/nginx-brotli:<nginx version>` to Docker Hub.

## Setup

Add repository secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (a Docker Hub access token).

## Usage

The module is loaded in `nginx.conf`; enable it in your config:

```
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/javascript application/json image/svg+xml;
```

Local build: `docker build -t nginx-brotli .`
