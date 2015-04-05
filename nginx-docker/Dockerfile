FROM ubuntu:14.10

MAINTAINER Peter Rossbach peter.rossbach@bee42.com @PRossbach

ENV NGINX_VERSION=1.7.11

ADD docker-stream-patch.txt /tmp/docker-stream-patch.txt

RUN apt-get update \
 && apt-get install -y \
  ca-certificates \
  wget \
  perl \
  libssl1.0.0 \
  libxslt1.1 \
  libgd3 \
  libxpm4 \
  libgeoip1 \
  libav-tools \
  gcc \
  g++ \
  make \
  libc6-dev \
  libpcre++-dev \
  libssl-dev \
  libxslt-dev \
  libgd2-xpm-dev \
  libgeoip-dev \
  && alias make="make -j$(awk '/^processor/ { N++} END { print N }' /proc/cpuinfo)" \
  && mkdir -p /tmp/nginx \
  && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O - | tar -zxf - -C /tmp/nginx --strip=1 \
  && cd /tmp/nginx \
  && ./configure --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin \
    --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --with-pcre-jit --with-ipv6 --with-http_ssl_module \
    --with-http_stub_status_module --with-http_realip_module \
    --with-http_addition_module --with-http_dav_module --with-http_geoip_module \
    --with-http_gzip_static_module --with-http_image_filter_module \
    --with-http_spdy_module --with-http_sub_module --with-http_xslt_module \
    --with-mail --with-mail_ssl_module \
  && cd /tmp/nginx \
  && patch src/http/ngx_http_upstream.c </tmp/docker-stream-patch.txt \
  && make \
  && make install \
  && apt-get purge -y --auto-remove gcc g++ make libc6-dev libpcre++-dev libssl-dev libxslt-dev libgd2-xpm-dev libgeoip-dev \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/nginx \
  && mkdir -p /var/lib/nginx/body \
  && mkdir -p /etc/nginx/conf.d \
  && adduser --system --no-create-home --disabled-login --disabled-password --group nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

VOLUME ["/var/cache/nginx"]

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]

ADD LICENSE /etc/LICENSE.nginx
RUN COPYDATE=`date  +'%Y'` \
 && echo "infrabricks nginx" >/etc/provisioned.nginx \
 && date >>/etc/provisioned.nginx \
 && echo >>/etc/provisioned.nginx \
 && echo " Copyright ${COPYDATE} by <peter.rossbach@bee42.com> bee42 solutions gmbh" >>/etc/provisioned.nginx
