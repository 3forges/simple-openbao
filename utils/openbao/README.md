# Helm OpenBAO

## Deploying

### FIrst Try: all defaults

Result:

* There is no serivce which is pending for being assigned an External IP
* In the stateful set, I see clear errors in logs:

```bash
pesto@pesto:~$ kubectl --context kind-openbao-cluster logs -f statefulset.apps/openbao
==> OpenBao server configuration:

Administrative Namespace:
             Api Address: http://10.244.0.9:8200
                     Cgo: disabled
         Cluster Address: https://openbao-0.openbao-internal:8201
   Environment Variables: BAO_ADDR, BAO_API_ADDR, BAO_CLUSTER_ADDR, BAO_K8S_NAMESPACE, BAO_K8S_POD_NAME, FOO_SERVICE_PORT, FOO_SERVICE_PORT_5678_TCP, FOO_SERVICE_PORT_5678_TCP_ADDR, FOO_SERVICE_PORT_5678_TCP_PORT, FOO_SERVICE_PORT_5678_TCP_PROTO, FOO_SERVICE_SERVICE_HOST, FOO_SERVICE_SERVICE_PORT, HOME, HOSTNAME, HOST_IP, KUBERNETES_PORT, KUBERNETES_PORT_443_TCP, KUBERNETES_PORT_443_TCP_ADDR, KUBERNETES_PORT_443_TCP_PORT, KUBERNETES_PORT_443_TCP_PROTO, KUBERNETES_SERVICE_HOST, KUBERNETES_SERVICE_PORT, KUBERNETES_SERVICE_PORT_HTTPS, NAME, OPENBAO_AGENT_INJECTOR_SVC_PORT, OPENBAO_AGENT_INJECTOR_SVC_PORT_443_TCP, OPENBAO_AGENT_INJECTOR_SVC_PORT_443_TCP_ADDR, OPENBAO_AGENT_INJECTOR_SVC_PORT_443_TCP_PORT, OPENBAO_AGENT_INJECTOR_SVC_PORT_443_TCP_PROTO, OPENBAO_AGENT_INJECTOR_SVC_SERVICE_HOST, OPENBAO_AGENT_INJECTOR_SVC_SERVICE_PORT, OPENBAO_AGENT_INJECTOR_SVC_SERVICE_PORT_HTTPS, OPENBAO_PORT, OPENBAO_PORT_8200_TCP, OPENBAO_PORT_8200_TCP_ADDR, OPENBAO_PORT_8200_TCP_PORT, OPENBAO_PORT_8200_TCP_PROTO, OPENBAO_PORT_8201_TCP, OPENBAO_PORT_8201_TCP_ADDR, OPENBAO_PORT_8201_TCP_PORT, OPENBAO_PORT_8201_TCP_PROTO, OPENBAO_SERVICE_HOST, OPENBAO_SERVICE_PORT, OPENBAO_SERVICE_PORT_HTTP, OPENBAO_SERVICE_PORT_HTTPS_INTERNAL, PATH, POD_IP, PWD, SHLVL, SKIP_CHOWN, SKIP_SETCAP, VERSION
              Go Version: go1.24.0
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level:
           Recovery Mode: false
                 Storage: file
                 Version: OpenBao v2.2.0, built 2025-03-05T13:07:08Z
             Version Sha: a2bf51c891680240888f7363322ac5b2d080bb23

==> OpenBao server started! Log data will stream in below:

2025-04-18T06:21:45.940Z [INFO]  proxy environment: http_proxy="" https_proxy="" no_proxy=""
2025-04-18T06:21:45.941Z [INFO]  core: Initializing version history cache for core
2025-04-18T06:21:53.462Z [INFO]  core: security barrier not initialized
2025-04-18T06:21:53.462Z [INFO]  core: seal configuration missing, not initialized
2025-04-18T06:21:58.414Z [INFO]  core: security barrier not initialized
2025-04-18T06:21:58.414Z [INFO]  core: seal configuration missing, not initialized
2025-04-18T06:22:03.461Z [INFO]  core: security barrier not initialized
2025-04-18T06:22:03.461Z [INFO]  core: seal configuration missing, not initialized
2025-04-18T06:22:08.456Z [INFO]  core: security barrier not initialized

```

### Second try: in dev mode

> Run Vault in "dev" mode. This requires no further setup, no state management,
> and no initialization. This is useful for experimenting with Vault without
> needing to unseal, store keys, et. al. All data is lost on restart - do not
> use dev mode for anything other than experimenting.
> See https://developer.hashicorp.com/vault/docs/concepts/dev-server to know more

I deploy in dev mode, using `--set server.dev.enabled=true`

And it worked.

SO I start looking at the different services, to find a web interface for example, using kubectl port-forward:

* This one gave me an empty reply from server:

```bash
kubectl --context kind-openbao-cluster -n pesto-openbao port-forward service/pesto-openbao 8201:8201 --address=192.168.1.16
```

* This one gave me the Web UI:

```bash
kubectl --context kind-openbao-cluster -n pesto-openbao port-forward service/pesto-openbao 8200:8200 --address=192.168.1.16
```

I got the token to login in the logs of the stateful set:

```bash
kubectl --context kind-openbao-cluster -n pesto-openbao logs -f statefulset.apps/pesto-openbao
```

gives:

```bash
3595be8374
2025-04-18T06:39:41.509Z [INFO]  core: successful mount: namespace="" path=secret/ type=kv version=""
2025-04-18T06:39:41.509Z [INFO]  secrets.kv.kv_5cd8642a: collecting keys to upgrade
2025-04-18T06:39:41.509Z [INFO]  secrets.kv.kv_5cd8642a: done collecting keys: num_keys=1
2025-04-18T06:39:41.509Z [INFO]  secrets.kv.kv_5cd8642a: upgrading keys finished
WARNING! dev mode is enabled! In this mode, OpenBao runs entirely in-memory
and starts unsealed with a single unseal key. The root token is already
authenticated to the CLI, so you can immediately begin using OpenBao.

You may need to set the following environment variables:

    $ export BAO_ADDR='http://[::]:8200'

The unseal key and root token are displayed below in case you want to
seal/unseal the Vault or re-authenticate.

Unseal Key: TYXCU0J9/tsgz7c2NIiUdAAXE4mAV7Y27LAq0ok4lps=
Root Token: root

Development mode should NOT be used in production installations!

```

I used the `token` authentication method, and `root` as the token value, as instructed in logs, and voilà:

I will also try to setup users at provisioning time:

```bash
  # Used to define commands to run after the pod is ready.
  # This can be used to automate processes such as initialization
  # or boostrapping auth methods.
  postStart: []
  # - /bin/sh
  # - -c
  # - /vault/userconfig/myscript/run.sh
```


```bash
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && export BAO_TOKEN="root" && bao auth enable userpass'
Success! Enabled userpass auth method at: userpass/
pesto@pesto:~$

```

And after enabling the userpass auth method, i can create a user:

```bash
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && export BAO_TOKEN="root" && bao write auth/userpass/users/pesto password="pesto"'
Success! Data written to: auth/userpass/users/pesto
pesto@pesto:~$

```

If I do not enable the userpass auth method, I will get this error:

```bash
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && export BAO_TOKEN="root" && bao write auth/userpass/users/pesto password="pesto"'
Error writing data to auth/userpass/users/pesto: Error making API request.

URL: PUT http://[::]:8200/v1/auth/userpass/users/pesto
Code: 404. Errors:

* no handler for route "auth/userpass/users/pesto". route entry not found.
command terminated with exit code 2

```

And now I can login with the new user:

```bash
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && bao login -method=userpass username=pesto password=pesto'
Success! You are now authenticated. The token information displayed below is
already stored in the token helper. You do NOT need to run "bao login" again.
Future OpenBao requests will automatically use this token.

Key                    Value
---                    -----
token                  s.V31nfWoDdaysmwX06lffxuBz
token_accessor         x7dX1il0zNtWIwlRq9K48gwF
token_duration         768h
token_renewable        true
token_policies         ["default"]
identity_policies      []
policies               ["default"]
token_meta_username    pesto
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && bao print token'
s.V31nfWoDdaysmwX06lffxuBz
pesto@pesto:~$

```

And after installing the `bao` cli in my Git bash for Windows, I could:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ export BAO_ADDR='http://192.168.1.16:8200'
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao login -method=userpass username=pesto password=pesto
Success! You are now authenticated. The token information displayed below is
already stored in the token helper. You do NOT need to run "bao login" again.
Future OpenBao requests will automatically use this token.

Key                    Value
---                    -----
token                  s.V2CHTPKeHesxs5xPnvxhdMb9
token_accessor         LaLhFhSfd7HNJ41y6n4njaku
token_duration         768h
token_renewable        true
token_policies         ["default"]
identity_policies      []
policies               ["default"]
token_meta_username    pesto

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao login -method=token token=root
Success! You are now authenticated. The token information displayed below is
already stored in the token helper. You do NOT need to run "bao login" again.
Future OpenBao requests will automatically use this token.

Key                  Value
---                  -----
token                root
token_accessor       1xFR5A5qSXsRcPRwW6FKJDP5
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]

Utilisateur@Utilisateur-PC MINGW64 ~

```

I then re-created the pesto user, by giving him the admin powers, so it can create a KV engine, for example, but basically so it can manage all features of OpenBAO vault:

```bash
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && export BAO_TOKEN="root" && bao delete auth/userpass/users/pesto'
Success! Data deleted (if it existed) at: auth/userpass/users/pesto
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && export BAO_TOKEN="root" && bao write auth/userpass/users/pesto password="pesto" policies="admin"'
Success! Data written to: auth/userpass/users/pesto
pesto@pesto:~$
pesto@pesto:~$ kubectl --context kind-openbao-cluster -n pesto-openbao exec -it pod/pesto-openbao-0 -- sh -c 'export BAO_ADDR="http://[::]:8200" && export BAO_TOKEN="root" && bao write auth/userpass/users/pesto password="pesto" policies="admins"'
Success! Data written to: auth/userpass/users/pesto
pesto@pesto:~$

```

```bash
cat <<EOF >./super.admin.policy.hcl
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch"]
}
EOF

export BAO_ADDR='192.168.1.16:8200'
export BAO_TOKEN='root'

bao login -method=token

bao policy write super.admin.policy ./super.admin.policy.hcl
bao write auth/userpass/users/pesto password="pesto" policies="super.admin.policy"
# bao secrets enable -version=2 kv
```

And now with the new policy, the pesto user really has all super powers, just like the root user.

Now i tried enabling kv engine v2, before I read this:

> when running a dev-mode server, the v2 `kv` secrets engine is enabled by default at the path `secret/` (for non-dev servers, it is currently v1).

I still could enable a version 2 KV engine at path `kv_v2/`:

```bash
bao secrets enable kv_v2
```

Then I tried creating secrets:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao kv put -mount=kv_v2 pesto_project/envs/dev/this/is/one/secretyeah some_password='SDR34sf5!@'
Error making API request.

URL: GET http://192.168.1.16:8200/v1/sys/internal/ui/mounts/kv_v2
Code: 403. Errors:

* preflight capability check returned 403, please ensure client's policies grant access to path "kv_v2/"

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao kv put -mount=secret pesto_project/envs/dev/this/is/one/secretyeah some_password='SDR34sf5!@'
====================== Secret Path ======================
secret/data/pesto_project/envs/dev/this/is/one/secretyeah

======= Metadata =======
Key                Value
---                -----
created_time       2025-04-18T13:38:27.333543282Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1


```

As I could see, with my pesto user, I am not allowed to create a new secret in the `kv_v2`

I then found how to create a new kv engine of type v1, and how to disable (delete?) it:

* COmmands:

```bash
bao secrets enable -path=kv_v2/pokus/pesto/rocks/with/terraform kv
bao secrets disable kv_v2/pokus/pesto/rocks/with/terraform



```

* Result:

```bash
$ bao secrets enable -path=kv_v2/pokus/pesto/rocks/with/terraform kv
Success! Enabled the kv secrets engine at: kv_v2/pokus/pesto/rocks/with/terraform/
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao secrets disable kv_v2/pokus/pesto/rocks/with/terraform
Success! Disabled the secrets engine (if it existed) at: kv_v2/pokus/pesto/rocks/with/terraform/

```


I then found how to create a new kv engine of type v2, and I tried again creating some secret in that new KV engine:

```bash
bao secrets enable -version=2 -path=kv_v2/pokus/pesto/rocks/with/terraform kv
# bao secrets disable kv_v2/pokus/pesto/rocks/with/terraform

bao kv put -mount=kv_v2/pokus/pesto/rocks/with/terraform pesto_project/envs/dev/this/is/one/secretyeah some_password='SDR34sf5!@'
```


And there I finally am :) : 

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao secrets enable -version=2 -path=kv_v2/pokus/pesto/rocks/with/terraform kv
Success! Enabled the kv secrets engine at: kv_v2/pokus/pesto/rocks/with/terraform/

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao kv put -mount=kv_v2/pokus/pesto/rocks/with/terraform pesto_project/envs/dev/this/is/one/secretyeah some_password='SDR34sf5!@'
====================================== Secret Path ======================================
kv_v2/pokus/pesto/rocks/with/terraform/data/pesto_project/envs/dev/this/is/one/secretyeah

======= Metadata =======
Key                Value
---                -----
created_time       2025-04-18T13:52:11.551416221Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1


```

Ok, Now I need to setup ACL Policies for:

* Users, organized with teams and organizations.

Now the next steps I will need to achieve, are:
* to have my OpenBAO protected with an SSL/TLS Cert, through NGINX.
* to add an approle: for integrating a tool like a pipeline service which will then be able to login without a username and or password, and proving its identity based on a signed JSON WEB TOKEN, jwt. see https://openbao.org/docs/auth/approle/


## Trying AppRoles

First quicky try

```bash
bao auth enable approle
```

Note that the super cow user policy I had set before was not enough to be alllowed to enable the approle auth method:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao auth enable approle
Error enabling approle auth: Error making API request.

URL: POST http://192.168.1.16:8200/v1/sys/auth/approle
Code: 403. Errors:

* 1 error occurred:
        * permission denied



Utilisateur@Utilisateur-PC MINGW64 ~
$ ls -alh *.hcl
-rw-r--r-- 1 Utilisateur 197121 86 Apr 18 15:02 super.admin.policy.hcl

Utilisateur@Utilisateur-PC MINGW64 ~
$ cat super.admin.policy.hcl
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch"]
}

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao login -method=token token=root
Success! You are now authenticated. The token information displayed below is
already stored in the token helper. You do NOT need to run "bao login" again.
Future OpenBao requests will automatically use this token.

Key                  Value
---                  -----
token                root
token_accessor       1xFR5A5qSXsRcPRwW6FKJDP5
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao auth enable approle
Success! Enabled approle auth method at: approle/


```


So I could witht he root user, enable the approle auth method at multiple different paths, like this:

```bash
bao auth enable approle
bao auth enable -path=pesto/pipelines/circleci approle
bao auth enable -path=pesto/pipelines/droneci approle
bao auth enable -path=pesto/pipelines/onedev approle
```

* Result:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao auth enable approle
Success! Enabled approle auth method at: approle/

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao auth enable approle -path=pesto/pipelines/circleci
Command flags must be provided before positional arguments. The following arguments will not be parsed as flags: [-path=pesto/pipelines/circleci]
Too many arguments (expected 1, got 2)

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao auth enable -path=pesto/pipelines/circleci approle
Success! Enabled approle auth method at: pesto/pipelines/circleci/

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao auth enable -path=pesto/pipelines/droneci approle
Success! Enabled approle auth method at: pesto/pipelines/droneci/

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao auth enable -path=pesto/pipelines/onedev approle
Success! Enabled approle auth method at: pesto/pipelines/onedev/

Utilisateur@Utilisateur-PC MINGW64 ~

```


Now i will try to authenticate using the app role method:

First try:

```bash

bao write auth/pesto/pipelines/droneci/login \
    role_id=db02de05-fa39-4855-059b-67221c5c2f63 \
    secret_id=6a174c20-f6de-a53c-74d2-6018fcceff64
```

Gives this pretty obvious result:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao write auth/pesto/pipelines/droneci/login \
    role_id=db02de05-fa39-4855-059b-67221c5c2f63 \
    secret_id=6a174c20-f6de-a53c-74d2-6018fcceff64
Error writing data to auth/pesto/pipelines/droneci/login: Error making API request.

URL: PUT http://192.168.1.16:8200/v1/auth/pesto/pipelines/droneci/login
Code: 400. Errors:

* invalid role or secret ID

```

We note this concept about AppRoles:

> An "AppRole" represents a set of OpenBao policies and login constraints that must be met to receive a token with those policies. The scope can be as narrow or broad as desired. An AppRole can be created for a particular machine, or even a particular user on that machine, or a service spread across machines. The credentials required for successful login depend upon the constraints set on the AppRole associated with the credentials.

SO we now need to create a role that we will use for authentication:

```bash
export APP_ROLE_PATH='pesto/pipelines/circleci'
export APP_ROLE_PATH='pesto/pipelines/onedev'
export APP_ROLE_PATH='pesto/pipelines/droneci'

export ROLE_NAME='pesto-ci-bot'

bao write auth/${APP_ROLE_PATH}/role/${ROLE_NAME} \
  secret_id_ttl=10m \
  token_num_uses=10 \
  token_ttl=20m \
  token_max_ttl=30m \
  secret_id_num_uses=40

bao read auth/${APP_ROLE_PATH}/role/${ROLE_NAME}
bao read auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/role-id
bao write -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/secret-id


```

Result:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ export APP_ROLE_PATH='pesto/pipelines/circleci'
export APP_ROLE_PATH='pesto/pipelines/onedev'
export APP_ROLE_PATH='pesto/pipelines/droneci'

export ROLE_NAME='pesto-ci-bot'

bao write auth/${APP_ROLE_PATH}/role/${ROLE_NAME} \
  secret_id_ttl=10m \
  token_num_uses=10 \
  token_ttl=20m \
  token_max_ttl=30m \
  secret_id_num_uses=40
Success! Data written to: auth/pesto/pipelines/droneci/role/pesto-ci-bot
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao read auth/pesto/pipelines/droneci/role/pesto-ci-bot
Key                        Value
---                        -----
bind_secret_id             true
local_secret_ids           false
secret_id_bound_cidrs      <nil>
secret_id_num_uses         40
secret_id_ttl              10m
token_bound_cidrs          []
token_explicit_max_ttl     0s
token_max_ttl              30m
token_no_default_policy    false
token_num_uses             10
token_period               0s
token_policies             []
token_strictly_bind_ip     false
token_ttl                  20m
token_type                 default
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao read auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/role-id
Key        Value
---        -----
role_id    3140a914-bb07-9f05-11fd-458186e819c7

Utilisateur@Utilisateur-PC MINGW64 ~
$ bao write -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/secret-id
Key                   Value
---                   -----
secret_id             f976b2c3-6e7e-63ab-2635-570d07c1c6c0
secret_id_accessor    37ce2986-ec1a-d5ec-4325-8d07dd3e13c6
secret_id_num_uses    40
secret_id_ttl         10m

```

Now I coudl successfully login using the new role-id and `secret-id` like this:

```bash
export APP_ROLE_PATH='pesto/pipelines/circleci'
export APP_ROLE_PATH='pesto/pipelines/onedev'
export APP_ROLE_PATH='pesto/pipelines/droneci'

export ROLE_NAME='pesto-ci-bot'

export MY_ROLE_ID='3140a914-bb07-9f05-11fd-458186e819c7'
export MY_SECRET_ID='f976b2c3-6e7e-63ab-2635-570d07c1c6c0'

bao write auth/${APP_ROLE_PATH}/login \
    role_id=${MY_ROLE_ID} \
    secret_id=${MY_SECRET_ID}
```

Result:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ export APP_ROLE_PATH='pesto/pipelines/circleci'
export APP_ROLE_PATH='pesto/pipelines/onedev'
export APP_ROLE_PATH='pesto/pipelines/droneci'

export ROLE_NAME='pesto-ci-bot'

export MY_ROLE_ID='3140a914-bb07-9f05-11fd-458186e819c7'
export MY_SECRET_ID='f976b2c3-6e7e-63ab-2635-570d07c1c6c0'

bao write auth/${APP_ROLE_PATH}/login \
    role_id=${MY_ROLE_ID} \
    secret_id=${MY_SECRET_ID}
Key                     Value
---                     -----
token                   s.DEoviNfepIITDYZeHOLaNAPc
token_accessor          gdOYT5C1dyK6M0MQ5XCZKGL1
token_duration          20m
token_renewable         true
token_policies          ["default"]
identity_policies       []
policies                ["default"]
token_meta_role_name    pesto-ci-bot


```

So, potentially, provided :
* that the authenticated bao user has the permissions to read the role id with the `bao read auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/role-id` command
* that he has the permissions to write to the endpoint with the `bao write -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/secret-id` command,

It can potentially login to the vault. Now the issue is that it would require that the user is logged in with a first method, to be able to authenticate with a second login method, yet:
* the first login would be odne with a user which has zero permissions in the BAO vault, except :
  * executing the `bao read auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/role-id` command.
  * executing the `bao write -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/secret-id` command.
* and the second user is the one which is allowed to read secrets:
  * a `ROLE_NAME` per bot user
  * each team could have any number of bot users, with different rights: the question then could be, how do we integrate LDAP or OIDC authentication, such that for every LDAP user group, at least one role is created: then there is also the


By the way, there a very handy option onoutput to just get the secret-id value:

```bash
bao write -field=secret_id -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/secret-id
```

gives:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao write -field=secret_id -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/secret-id
4333298a-c561-47f4-5897-61ad845e4a8f

```

So I could go:

```bash
# ---
# A login stage first:
export BAO_ADDR=http://192.168.1.16:8200
bao login -method=token token=root
# ---
# 
export APP_ROLE_PATH='pesto/pipelines/circleci'
export APP_ROLE_PATH='pesto/pipelines/onedev'
export APP_ROLE_PATH='pesto/pipelines/droneci'

export ROLE_NAME='pesto-ci-bot'

# --- 
# 
# bao write -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME} \
#   secret_id_ttl=10m \
#   token_num_uses=10 \
#   token_ttl=20m \
#   token_max_ttl=30m \
#   secret_id_bound_cidrs='192.168.1.0/24' \
#   secret_id_num_uses=40

# ---
# Below I restrict to only one IP Address: 192.168.1.16
# And I will test those commands:
# From the Machine with 192.168.1.12 ip address
# From the machine with 192.168.1.16 ip address
# - - 
bao write -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME} \
  secret_id_ttl=10m \
  token_num_uses=10 \
  token_ttl=20m \
  token_max_ttl=30m \
  secret_id_bound_cidrs='192.168.1.16/32' \
  secret_id_num_uses=40

# bao write -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME} \
#   secret_id_ttl=10m \
#   token_num_uses=10 \
#   token_ttl=20m \
#   token_max_ttl=30m \
#   secret_id_bound_cidrs='192.168.1.12/32' \
#   secret_id_num_uses=40


export MY_ROLE_ID=$(bao read -field=role_id auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/role-id)

export MY_SECRET_ID=$(bao write -field=secret_id -f auth/${APP_ROLE_PATH}/role/${ROLE_NAME}/secret-id)

bao write auth/${APP_ROLE_PATH}/login \
    role_id=${MY_ROLE_ID} \
    secret_id=${MY_SECRET_ID}
```

And here no matter from which machine I was trying to log, I got this response:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~
$ bao write auth/${APP_ROLE_PATH}/login \
    role_id=${MY_ROLE_ID} \
    secret_id=${MY_SECRET_ID}
Error writing data to auth/pesto/pipelines/droneci/login: Error making API request.

URL: PUT http://192.168.1.16:8200/v1/auth/pesto/pipelines/droneci/login
Code: 400. Errors:

* source address "127.0.0.1" unauthorized by CIDR restrictions on the role: %!w(<nil>)


```

This is because I access the OpenBAO vault using a `kubectl port-forward`: it now time to set up the reverse proxy and re-run that test.

see also roles in the OIDC setup: https://openbao.org/docs/auth/jwt/oidc-providers/kubernetes/#kubernetes

## About the Ingress

I did not see any external ip pending, and:

* here there is something related to ingres / loadbalancer https://openbao.org/docs/platform/k8s/helm/terraform/#annotations
*

In [the helm chart values.yaml](https://openbao.github.io/openbao-helm/charts/openbao/values.yaml) there is something which might help:

```Yaml
  # Ingress allows ingress services to be created to allow external access
  # from Kubernetes to access Vault pods.
  # If deployment is on OpenShift, the following block is ignored.
  # In order to expose the service, use the route section below
  ingress:
    enabled: false
    labels: {}
      # traffic: external
    annotations: {}
      # |
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"
      #   or
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"

    # Optionally use ingressClassName instead of deprecated annotation.
    # See: https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation
    ingressClassName: ""
```

And there is also this:

```Yaml

    # Configures the service type for the main Vault service.  Can be ClusterIP
    # or NodePort.
    #type: ClusterIP
```

But I think there shodl be an ingress controller in the Kubernetes CLuster, and an ingress route to the OpenBAO vault service, the ingress cotnroller will then be nginx for me, even if i will already have an nginx in the room zero


## References

* The Helm Chart documentation:
  * 
* The helm chart `values.yaml`: https://openbao.github.io/openbao-helm/charts/openbao/values.yaml