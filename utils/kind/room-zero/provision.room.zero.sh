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

export OPENBAO_KND_EXTERNAL_IP=$(kubectl -n pesto \
  get services \
  -l component=proxy-public,app=openbao \
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


figlet 'Room Zero'

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
    
    upstream jupytherhub {
        ip_hash;
        server $OPENBAO_KND_EXTERNAL_IP:80;
    }

    server {
        listen       80;
        listen  [::]:80;
        # server_name  localhost;
        # --- 
        # ${OPENBAO_FQDN}: i would then add in my [/etc/hosts] an entry to map it to the public IP of my VM
        server_name ${OPENBAO_FQDN};

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

            proxy_pass http://jupytherhub;
        }
    }
}
EOF


docker-compose -f ./docker-compose.room.zero.yaml up -d


sleep 3s

figlet 'Connect Room Zero'

docker network connect "${KND_NET_NAME}" "${ROOM_ZERO_CONTAINER_NAME}"





