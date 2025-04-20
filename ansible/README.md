# The Ansible Playbook

## Requirements

```bash

```

## Running the playbook

Running ansible on windows may be a headache, and since I do not want to spend any time on that question, I recommend running the playbook in a docker container, on a linux machine where docker is installed:

Here on the VM where I will install the whole OpenBAO Stack.

Here is how:

```bash
export DESIRED_VERSION='feature/first/docker-compose'

git clone git@github.com:3forges/simple-openbao.git

cd ./simple-openbao/

git checkout ${DESIRED_VERSION}

cd ./ansible/

export ANSIBLE_IMG='quay.io/ansible/awx-ee:24.6.1'

export CONTAINER_NAME='my-ansible-runner'

docker pull ${ANSIBLE_IMG}


cat <<EOF >./ansible.cmd.sh

# ---
# Ansible callback yaml requires 
# the 'community.general' ansible collection to be installed 
# - 
# 
ansible-galaxy collection install community.general

export ANSIBLE_CALLBACKS_ENABLED=profile_tasks
export ANSIBLE_STDOUT_CALLBACK=yaml 
# export ANSIBLE_ROLES_PATH="\$(pwd)/ansible/roles"
export ANSIBLE_ROLES_PATH="\$(pwd)/roles"

ansible-playbook -vvv -i ./inventories/dev/hosts.yml \
  -e "my_var1=value1" \
  -e "my_var2=value2" \
  -e "my_var3=value3" \
  ./playbooks/provision.yml
EOF


docker run --name ${CONTAINER_NAME} -itd \
  --restart unless-stopped \
  -v $PWD:/runner/workspace:rw \
  ${ANSIBLE_IMG} bash



# docker cp ./ansible.cmd.sh ${CONTAINER_NAME}:/runner/workspace

docker exec -it -w /runner/workspace ${CONTAINER_NAME} bash -c 'pwd && ls -alh'

```
