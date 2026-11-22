# Build
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# Gatsby writes .js.map alongside every bundle. Publishing those hands the full
# original source to anyone who asks for the URL — exactly how the source for
# two other sites in this account was recovered. They are dropped rather than
# served.
RUN find public -name '*.map' -delete

# Serve
#
# The official nginx image, set up below to run without root. The stock setup
# needs root to write its pid file and cache, and the cluster runs containers
# with every Linux capability dropped.
#
# This used to build on nginxinc/nginx-unprivileged, which is the same nginx
# with those changes already made. A separate project publishes it, and it fell
# behind: on 2026-11-22 its newest 1.30 image was still nginx 1.30.6 from
# October, four days after the official image shipped 1.30.7 with fixes for
# four critical vulnerabilities. `apk upgrade` cannot close that gap, because
# nginx in both images is nginx.org's package, not Alpine's. The official image
# is rebuilt with each nginx release.
#
# 1.30 is nginx's current stable line (1.27 was a mainline release that stopped
# receiving fixes). The base image arrives with OS packages behind what Alpine
# has fixed, so they are upgraded here; the ADD before it is what makes that
# step re-run whenever Alpine publishes -- BuildKit re-checks a remote ADD on
# every build, while a RUN whose text has not changed is reused from the cache.
FROM nginx:1.30-alpine
ADD https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64/APKINDEX.tar.gz /tmp/apkindex.tar.gz
RUN apk upgrade --no-cache

# What nginx-unprivileged changes, line for line: no `user` directive, the pid
# file and temp directories under /tmp, and the config and cache owned by the
# nginx user (uid 101).
RUN sed -i '/user  nginx;/d' /etc/nginx/nginx.conf \
 && sed -i 's,\(/var\)\{0\,1\}/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf \
 && sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf \
 && chown -R 101:0 /etc/nginx /var/cache/nginx \
 && chmod -R g+w /etc/nginx /var/cache/nginx
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build --chown=nginx:nginx /app/public /usr/share/nginx/html
USER 101
# Fails the build, not the rollout, if nginx cannot start as this user with this
# config -- which is what happens if a future base image moves the lines the sed
# above edits.
RUN nginx -t && rm -f /tmp/nginx.pid
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -q --spider http://127.0.0.1:3000/ || exit 1
