#!/bin/bash
# set -uxo pipefail
set -o errexit

source ~/.bashrc

export OPS_HOME=${HOME}/.room.zero

if [ -d ${OPS_HOME} ]; then
  cd ${OPS_HOME}
  docker-compose -f ./docker-compose.room.zero.yaml down || true
  cd ~
  rm -fr ${OPS_HOME}
fi;

mkdir -p ${OPS_HOME}

cd ${OPS_HOME}
echo "# -------------------- # -------------------- "
echo "# -------------------- # -------------------- "
echo "# -------------------- "
ls -alh ~/.room.zero.env.sh
echo "# -------------------- "
echo "# --- content of [~/.room.zero.env.sh]"
cat -n ~/.room.zero.env.sh


chmod +x ~/.room.zero.env.sh
source ~/.room.zero.env.sh

# export OPENBAO_KND_EXTERNAL_IP=$(cat ~/.room.zero.env.sh | grep 'OPENBAO_KND_EXTERNAL_IP' | awk -F '=' '{ print $NF }')
# ---
# The Ip Address of the OpenBAO Service will be the External IP of the Ngonx Ingress Controller 
export OPENBAO_KND_EXTERNAL_IP=$(kubectl --context kind-openbao-cluster \
  -n ingress-nginx get services \
  -l app.kubernetes.io/instance=ingress-nginx \
  -l app.kubernetes.io/component=controller \
  --field-selector spec.type=LoadBalancer \
  -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")

echo "OPENBAO_KND_EXTERNAL_IP=[${OPENBAO_KND_EXTERNAL_IP}]"


# ---
#  
export KND_NET_NAME=$(cat ~/.room.zero.env.sh | grep 'KND_NET_NAME' | awk -F '=' '{ print $NF }' | sed 's#"##g' | sed "s#'##g")

export ROOM_ZERO_CONTAINER_NAME=${ROOM_ZERO_CONTAINER_NAME:-'room_zero'}

# --- 
#  ROOM_ZERO_BIND_ADDR: that's the Ip address on which the
#  internet traffic arrives, basically the same ip address 
#  than the SSH server binds on. This is exactly either
#  equals to 0.0.0.0 or, the private Ip Address of the GCP Compute Instance
# --- 
export ROOM_ZERO_BIND_ADDR=$(cat ~/.room.zero.env.sh | grep 'ROOM_ZERO_BIND_ADDR' | awk -F '=' '{ print $NF }' | sed 's#"##g' | sed "s#'##g")
# export ROOM_ZERO_BIND_ADDR='0.0.0.0'

export OPENBAO_FQDN=${OPENBAO_FQDN:-"openbao.pesto.io"}
echo "# -------------------- "
echo "# --- After [source ~/.room.zero.env.sh] "
echo "# --- "
echo "OPENBAO_KND_EXTERNAL_IP=[$OPENBAO_KND_EXTERNAL_IP]"
echo "KND_NET_NAME=[${KND_NET_NAME}]"
echo "ROOM_ZERO_CONTAINER_NAME=[${ROOM_ZERO_CONTAINER_NAME}]"
echo "# --- "
echo "# -------------------- "
echo "# -------------------- # -------------------- "
echo "# -------------------- # -------------------- "

if [ "x${OPENBAO_KND_EXTERNAL_IP}" == "x" ]; then
  echo "ERROR!!! The 'OPENBAO_KND_EXTERNAL_IP' env. var. is not set!"
  exit 7
fi;

if [ "x${KND_NET_NAME}" == "x" ]; then
  echo "ERROR!!! The 'KND_NET_NAME' env. var. is not set!"
  exit 7
fi;

if [ "x${ROOM_ZERO_CONTAINER_NAME}" == "x" ]; then
  echo "ERROR!!! The 'ROOM_ZERO_CONTAINER_NAME' env. var. is not set!"
  exit 7
fi;

if [ "x${ROOM_ZERO_BIND_ADDR}" == "x" ]; then
  echo "ERROR!!! The 'ROOM_ZERO_BIND_ADDR' env. var. is not set!"
  exit 7
fi;

if [ "x${OPENBAO_FQDN}" == "x" ]; then
  echo "ERROR!!! The 'OPENBAO_FQDN' env. var. is not set!"
  exit 7
fi;

# --- Certificate files
if [ "x${OPENBAO_TLS_CERT_PATH}" == "x" ]; then
  echo "ERROR!!! The 'OPENBAO_TLS_CERT_PATH' env. var. is not set!"
  exit 7
fi;

if ! [ -f ${OPENBAO_TLS_CERT_PATH} ]; then
  echo "ERROR - The OPENBAO_TLS_CERT_PATH=[${OPENBAO_TLS_CERT_PATH}] file does not exist, itmust exist"
  exit 23
fi;

if [ "x${OPENBAO_TLS_CERT_KEY_PATH}" == "x" ]; then
  echo "ERROR!!! The 'OPENBAO_TLS_CERT_KEY_PATH' env. var. is not set!"
  exit 7
fi;

if ! [ -f ${OPENBAO_TLS_CERT_KEY_PATH} ]; then
  echo "ERROR - The OPENBAO_TLS_CERT_KEY_PATH=[${OPENBAO_TLS_CERT_KEY_PATH}] file does not exist, itmust exist"
  exit 23
fi;




# figlet 'Room Zero'

# the docker-compose of the nginx service we will spin up
docker-compose -f ./docker-compose.room.zero.yaml down || true
cat <<EOF >./docker-compose.room.zero.yaml
version: '3.7'

services:
  room-zero:
    image: nginx:1.19.2-alpine
    hostname: room-zero
    container_name: ${ROOM_ZERO_CONTAINER_NAME}
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ${OPENBAO_TLS_CERT_PATH}:/etc/nginx/certs/${OPENBAO_FQDN}.cert:ro
      - ${OPENBAO_TLS_CERT_KEY_PATH}:/etc/nginx/certs/${OPENBAO_FQDN}.key:ro
    ports:
      - "${ROOM_ZERO_BIND_ADDR}:80:80"
      # - "${ROOM_ZERO_BIND_ADDR}:8081:80"
    networks:
      room_zero_net:
        aliases:
          - room-zero.pesto.io

networks:
  room_zero_net:
    driver: bridge
EOF

#################
##### OKAY I WILL TRY THAT FIRST VERSION:
# I still need to geenerate the certs, and do all needed to 
# place them in container image by docker volumes...
cat <<EOF >./nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  4096;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream; 

    log_format  main  'room-zero-pesto - \$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;

    # include /etc/nginx/conf.d/*.conf;
    
    upstream openbao {
        ip_hash;
        server $OPENBAO_KND_EXTERNAL_IP:443;
    }

    server {
        # listen       80;
        # listen  [::]:80;
        listen       443 ssl;
        listen  [::]:443 ssl;
        # server_name  localhost;
        # --- 
        # ${OPENBAO_FQDN}: i would then add in my [/etc/hosts] an entry to map it to the public IP of my VM
        server_name ${OPENBAO_FQDN};
        ssl_certificate /etc/nginx/certs/${OPENBAO_FQDN}.cert;
        ssl_certificate_key /etc/nginx/certs/${OPENBAO_FQDN}.key;
        # ---
        # Stronger than the default [ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;] see https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers "HIGH:!aNULL:!MD5:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256";
        ssl_prefer_server_ciphers on;

        # To allow special characters in headers
        ignore_invalid_headers off;
        # Allow any size file to be uploaded.
        # Set to a value such as 1000m; to restrict file size to a specific value
        client_max_body_size 0;
        # To disable buffering
        proxy_buffering off;
        proxy_request_buffering off;

        location / {
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-NginX-Proxy true;

            # This is necessary to pass the correct IP to be hashed
            real_ip_header X-Real-IP;

            proxy_connect_timeout 300;
            
            # To support websocket
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            
            chunked_transfer_encoding off;
            
            # ---
            #  I will for now assume that 
            #  the connection between nginx 
            #  and the reverse-proxied openbao service 
            #  is NOT secured, and when I want to secure with https encryption that part too, I will use:
            #  > This for MTLS (client TLS cert authentication, nginx authenticate to the reverse proxied server using a client cert) https://docs.nginx.com/nginx/admin-guide/security-controls/securing-http-traffic-upstream/
            #  > Or something lighter: NGINX will just need to trust the TLS cert broadcasted by the reverse-proxied openbao 
            # proxy_pass https://openbao;
            proxy_pass http://openbao;
        }
    }
}
EOF


docker-compose -f ./docker-compose.room.zero.yaml up -d


sleep 3s

figlet 'Connect Room Zero'

docker network connect "${KND_NET_NAME}" "${ROOM_ZERO_CONTAINER_NAME}"
