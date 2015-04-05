FROM infrabricks/nginx:1.7.11-docker

MAINTAINER Peter Rossbach peter.rossbach@bee42.com @PRossbach

RUN rm /etc/nginx/conf.d/*.conf
COPY powerstrip.conf /etc/nginx/conf.d/powerstrip.conf

EXPOSE 2376

ADD LICENSE /etc/LICENSE.nginx
RUN COPYDATE=`date  +'%Y'` \
 && echo "infrabricks nginx" >/etc/provisioned.nginx \
 && date >>/etc/provisioned.nginx \
 && echo >>/etc/provisioned.nginx \
 && echo " Copyright ${COPYDATE} by <peter.rossbach@bee42.com> bee42 solutions gmbh" >>/etc/provisioned.nginx
