# Based on https://github.com/nginx/docker-nginx/tree/master/modules/Dockerfile
ARG NGINX_FROM_IMAGE=nginx:mainline
FROM ${NGINX_FROM_IMAGE} AS builder

ARG ENABLED_MODULES="brotli"

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-suggests --no-install-recommends \
                patch make wget git devscripts debhelper dpkg-dev \
                quilt lsb-release build-essential libxml2-utils xsltproc \
                equivs git g++ libparse-recdescent-perl \
    && XSLSCRIPT_SHA512="f7194c5198daeab9b3b0c3aebf006922c7df1d345d454bd8474489ff2eb6b4bf8e2ffe442489a45d1aab80da6ecebe0097759a1e12cc26b5f0613d05b7c09ffa *stdin" \
    && wget -O /tmp/xslscript.pl https://raw.githubusercontent.com/nginx/xslscript/9204424259c343ca08a18a78915f40f28025e093/xslscript.pl \
    && if [ "$(cat /tmp/xslscript.pl | openssl sha512 -r)" = "$XSLSCRIPT_SHA512" ]; then \
        chmod +x /tmp/xslscript.pl; \
        mv /tmp/xslscript.pl /usr/local/bin/; \
    else \
        echo "XSLScript checksum verification failed!"; \
        exit 1; \
    fi \
    && git clone -b ${NGINX_VERSION}-${PKG_RELEASE%%~*} https://github.com/nginx/pkg-oss/ \
    && cd pkg-oss \
    && mkdir /tmp/packages \
    && for module in $ENABLED_MODULES; do \
        echo "Building $module for nginx-$NGINX_VERSION"; \
        cd /pkg-oss/debian; \
        make rules-module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
        mk-build-deps --install --tool="apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes" debuild-module-$module/nginx-$NGINX_VERSION/debian/control; \
        make module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
        find ../../ -maxdepth 1 -mindepth 1 -type f -name "*.deb" -exec mv -v {} /tmp/packages/ \;; \
        BUILT_MODULES="$BUILT_MODULES $module"; \
    done \
    && echo "BUILT_MODULES=\"$BUILT_MODULES\"" > /tmp/packages/modules.env

FROM ${NGINX_FROM_IMAGE}
RUN --mount=type=bind,target=/tmp/packages/,source=/tmp/packages/,from=builder \
    apt-get update \
    && . /tmp/packages/modules.env \
    && for module in $BUILT_MODULES; do \
           apt-get install --no-install-suggests --no-install-recommends -y /tmp/packages/nginx-module-${module}_${NGINX_VERSION}*.deb; \
       done \
    && rm -rf /var/lib/apt/lists/ \
    && sed -i '1i load_module modules/ngx_http_brotli_filter_module.so;\nload_module modules/ngx_http_brotli_static_module.so;' /etc/nginx/nginx.conf
