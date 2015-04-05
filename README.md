# Powerstrip docker-machine weave demo

![logo](https://raw.githubusercontent.com/infrabricks/powerstrip-demo/master/logo.png)

* Install and download https://github.com/docker/machine
* If you use multiple machines, setup a docker registry mirror!
* Use powerstrip with docker-machine
* Setup powerstrip with TLS

![powerstrip-tls](https://raw.githubusercontent.com/infrabricks/powerstrip-demo/master/images/powerstrip-tls.png)

## Simple out of the box powerstrip usage

![powerstrip-weave](https://raw.githubusercontent.com/infrabricks/powerstrip-demo/master/images/powerstrip-weave.png)

### Create you first powerstrip weave machine

Add mirror to your installation!

```
$ docker-machine create -d virtualbox weave-01
$ docker-machine ssh weave-01
> sudo sh
> echo "EXTRA_ARGS=\"\$EXTRA_ARGS --registry-mirror=http://devcache:5000\"">> /var/lib/boot2docker/profile
> echo "192.168.99.100 devcache" >>/etc/hosts
> /etc/init.d/docker stop
> /etc/init.d/docker start
```

Create your powerstrip demo weave setup at your host share

* https://github.com/clusterhq/powerstrip

```
cd /Users/peter
mkdir -p powerstrip-demo
cd powerstrip-demo
$ cat >adapters.yml <<EOF
endpoints:
  "POST /*/containers/create":
    pre: [weave]
  "POST /*/containers/*/start":
    post: [weave]
  "POST /*/containers/*/restart":
    post: [weave]
adapters:
  weave: http://weave/v1/extension
EOF
```

Create you powerstrip weave composition:

```
cat >docker-compose.yml <EOF
weave
  image: binocarlos/powerstrip-weave
  ports:
    - "80"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock \
  command: launch
powerstrip:
  image: clusterhq/powerstrip
  ports:
   - "2375:2375"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - adapters.yml:/etc/powerstrip/adapters.yml
  links:
   - weave:weave
EOF
```

* powerstrip-weave start zettio weave image!

If you want a weave cli use this:

```
_weave() {
  docker exec -ti powerstripdemo_weave_1 /srv/app/run.sh weave $@
}

alias weave=_weave
weave status
```

#### Install docker-compose at boot2docker installation

```
$ docker run --rm --entrypoint=/scripts/install -v /usr/local/bin:/data infrabricks/docker-compose
$ docker-machine ssh weave-01 "cd $(pwd) ; docker-compose up"
```

Now you can access docker-compose also from your windows system,
if your sources are created at `c:\Users\<your account>\powerstrip-demo`.
You must install the git/bash tools from boot2docker package!

```
$ docker-machine ssh weave-01
> export DOCKER_HOST=tcp://127.0.0.1:2375
docker ps
```

or

```
$ docker-machine ssh weave-01 "/bin/sh -c "docker -H tcp://127.0.0.1:2375 ps"
```

#### Start a container

You tell powerstrip-weave what IP address you want to give a container by using the `WEAVE_CIDR` environment variable for that new container - here we run a database server:

```
$ docker run -d --name mysql \
    -e WEAVE_CIDR=10.255.0.1/8 \
    -e MYSQL_ROOT_PASSWORD=mysecretpassword \
    mysql
```

weave network connected

```
docker@dev-test2:~$ docker exec -ti mysql /bin/bash
root@21654635c0cd:/# ip ro show
default via 172.17.42.1 dev eth0
10.0.0.0/8 dev ethwe  proto kernel  scope link  src 10.255.0.1
172.17.0.0/16 dev eth0  proto kernel  scope link  src 172.17.0.17
224.0.0.0/4 dev ethwe  scope link
```

### install second powerstrip weave machine

```
$ docker-machine create -d virtualbox weave-02
$ docker-machine ip weave-01
$ docker-machine ssh weave-02
> sudo sh
> echo "EXTRA_ARGS=\"\$EXTRA_ARGS --registry-mirror=http://devcache:5000\"">> /var/lib/boot2docker/profile
> echo "192.168.99.100 devcache" >>/etc/hosts
> echo "192.168.99.102 weave-01" >>/etc/hosts
> /etc/init.d/docker stop
> /etc/init.d/docker start
> docker run --rm --entrypoint=/scripts/install -v /usr/local/bin:/data infrabricks/docker-compose
```

```
cd /Users/peter/powerstrip-demo
cat >adapters-debug.yml <<EOF
version: 1
endpoints:
  "POST /*/containers/create":
    pre: [debug, weave, debug]
  "POST /*/containers/*/start":
    post: [debug, weave, debug]
adapters:
  debug: http://debug/extension
  weave: http://weave/extension
EOF
cat >docker-compose-weave-02.yml <<EOF
weave:
  image: binocarlos/powerstrip-weave
  ports:
    - "80"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  command: launch $(docker-machine ip weave-01)
debug:
    image: binocarlos/powerstrip-debug
    ports:
      - "80"
powerstrip:
  image: clusterhq/powerstrip
  ports:
   - "2375:2375"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - adapters-debug.yml:/etc/powerstrip/adapters.yml
  links:
   - weave:weave
   - debug:debug
EOF
> docker-compose -f docker-compose-weave2.yml up -d
```

**WARNING**: Here you must use the weave-01 IP-address. The example
use subshell feature, but variable access isn't supported yet form docker-compose 1.1.0. Sometimes IP address from a docker machine can changed after reboot!

```
weave:
  image: binocarlos/powerstrip-weave
  ports:
    - "80"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  command: launch 192.168.99.102
```

Now you can start a container and ping your mysql:

```
$ docker-machine ssh weave-02
> DOCKER_HOST=tcp://127.0.0.1:2375
> docker run -ti --rm -e -e WEAVE_CIDR=10.255.0.2/8 ubuntu
> ping 10.255.0.1 -c 1
```

## Setup powerstrip with TLS

Currently powerstrip docker extension show case version doesn't support tls.
If you plan easy transparent access from your MAC, with machine and swarm, it is a good idea to setup TLS.

**The plan**:

* use nginx with docker-machine boot2docker certs
  * use 2376 as ssl port
  * accept only access with correct signed client certs
* fix boot2docker profile only use local unix socket
* use host only powerstip 2375 port for powerstrip
* build nginx with docker stream patch
   * https://blog.jtlebi.fr/2014/12/12/how-to-run-docker-behind-an-nginx-reverse-proxy/
  * use 1.7.11 http://hg.nginx.org/nginx/rev/2b3b737b5456
  * Build NGINX form source with docker: (Jean-Tiare LE BIGOT) https://github.com/sameersbn/docker-nginx
  * http://nginx.org/en/download.html

### Check my powerstrip TLS experiment

```
$ docker-machine create -d virtualbox weave-03
$ powerstrip-demo/nginx-docker

$ eval $(docker-machine env weave-03)
# build my patched nginx 1.7.11
$ ./build.sh
$ docker-machine ssh weave-03
> sudo sh
# use only docker local unix socket
> cat >/var/lib/boot2docker/profile <<EOF
DOCKER_TLS=no
DOCKER_HOST=" "
EXTRA_ARGS="--label=provider=virtualbox --registry-mirror=http://devcache:5000\"
EOF
> /etc/init.d/docker stop
> /etc/init.d/docker start
# install docker compose >/var/lib/boot2docker/bootlocal.sh for restart!
> docker run --rm --entrypoint /scripts/install -v /usr/local/bin:/data infrabricks/docker-compose
> cd /Users/peter/powerstrip-demo
> docker-compose -f docker-compose-tls.yml up -d
> exit
> exit
# access nginx proxy from your host
$ eval $(docker-machine env weave-03)
$ docker ps -a
# with the docker patch,  attach works via nginx-> powerstrip > docker-daemon
$ docker run -ti --rm ubuntu
...
```

### Todo

* Support regenerate certs after failure or IP change!
  * After IP Adress changed regenerate local docker-compose
  * Detect you weave router/partner?
  * Setup at bootlocal.sh to restart
* build your own certs and ca...
  * http://wiki.nginx.org/HttpSslModule#Generate_Certificates
  * https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu-12-04
  * https://aralbalkan.com/scribbles/setting-up-ssl-with-nginx-using-a-namecheap-essentialssl-wildcard-certificate-on-digitalocean/
* check swarm integration
  * auto setup swarm agent container if ip change at bootlocal.sh
* sometimes docker-maschine reinstall /var/lib/boot2docker/profile
  * if ip adresse change
  * After a connection failure
  * you use the command `docker-machine regenerate-certs <machine>``
* Limit the usage: Add access control to your nginx conf
* check with weave

### build the nginx docker patched version

```
cd nginx-docker
./build.sh
```

### Review patch

Use your nginx version

```
hg clone http://hg.nginx.org/nginx -r "release-1.7.11"
cd nginx
```

Patch it with `nginx-docker/docker-stream-patch.txt`
* https://blog.jtlebi.fr/2014/12/12/how-to-run-docker-behind-an-nginx-reverse-proxy/

## Use weave commands

```
_weave() {
  docker exec -ti powerstrip-weave /srv/app/run.sh weave $@
}

alias weave=_weave
weave status
```

or

```
$ docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    binocarlos/powerstrip-weave status

# You can run normal weave network commands like expose and attach:

$ docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    binocarlos/powerstrip-weave expose 10.255.0.1/8
```

Read more about weave:

* https://github.com/zettio/weave
* http://zettio.github.io/weave/

### weave links

You are now at IP buisness links with ENV Parameter docker-compose has no `--add-host parameter`

```
api:
  build: api
  command: node /srv/app/index.js
  environment:
   - WEAVE_CIDR=10.255.0.10/8
   - REMOTE_VALUE=oranges
server:
  build: server
  command: node /srv/app/index.js
  ports:
   - "8082:80"
  environment:
   - WEAVE_CIDR=10.255.0.11/8
   - API_IP=10.255.0.10
```


Use crane instead docker-compose

https://github.com/michaelsauter/crane

```
cat >crane.yaml <<EOF
containers:
  api:
    dockerfile: api
    run:
      cmd: "node /srv/app/index.js"
      environment: [ "WEAVE_CIDR=10.255.0.10/8", "REMOTE_VALUE=oranges" ]
      detach: true
  server:
    dockerfile: server
    run:
      cmd: "node /srv/app/index.js"
      expose: [ "8082:80" ]
      add-host: [ "10.255.0.10 api" ]
      environment: [ "WEAVE_CIDR=10.255.0.11/8" ]
      detach: true
EOF
crane lift
```

## start a powerstrip debug container

```
$ docker run -ti --rm \
    --name powerstrip-debug \
    --expose 80 \
    binocarlos/powerstrip-debug

$ cat >adapters-debug.yml <<EOF
version: 1
endpoints:
  "POST /*/containers/create":
    pre: [debug, weave, debug]
  "POST /*/containers/*/start":
    post: [debug, weave, debug]
adapters:
  debug: http://debug/extension
  weave: http://weave/extension
EOF
```

```
$ docker run -d \
    --name powerstrip \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v adapters-debug.yml:/etc/powerstrip/adapters.yml \
    --link powerstrip-weave:weave \
    --link powerstrip-debug:debug \
    -p 2378:2375 \
    clusterhq/powerstrip
```

## Source code

* [infrabricks/powerstrip-demo](https://github.com/infrabricks/powerstrip-demo)

## Contact

For bugs, questions, comments, corrections, suggestions, etc., open an issue in
 [infrabricks/powerstrip-demo](https://github.com/infrabricks/powerstrip-demo/issues) with a title starting with `[powerstrip-demo] `.

Or just [click here](https://github.com/infrabricks/powerstrip-demo/issues/new?title=%5Bpowerstrip-demo%5D%20) to create a new issue.

## License

Copyright (c) 2014-2015 [bee42 solutions Gmbh- Peter Rossbach](http://www.bee42.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

More details read the [project license file](https://raw.githubusercontent.com/infrabricks/powerstrip-demo/master/LICENSE)!

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## References

* https://github.com/binocarlos/powerstrip-weave
* https://github.com/infrabricks/docker-compose
* Nginx Patch docker stream  
https://blog.jtlebi.fr/2014/12/12/how-to-run-docker-behind-an-nginx-reverse-proxy/
* http://wiki.nginx.org/HttpSslModule#Generate_Certificates
* https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-nginx-for-ubuntu-12-04
* https://aralbalkan.com/scribbles/setting-up-ssl-with-nginx-using-a-namecheap-essentialssl-wildcard-certificate-on-digitalocean/
* http://tech.themecloud.io/a-secured-docker-registry/
