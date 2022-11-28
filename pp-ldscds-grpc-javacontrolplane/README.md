

## Usage

First create network

```bash
docker network create \
  --subnet=172.70.0.0/16 \
  --gateway=172.70.0.1 \
  envoymeshnetwork
```

Then `./run2.sh`

## Ref 

[envoyproxy/java-control-plane](https://github.com/envoyproxy/java-control-plane)

[Dynamic configuration (control plane)  Official DOC](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/dynamic-configuration-control-plane)

[dynamic-config-cp Github](https://github.com/envoyproxy/envoy/tree/main/examples/dynamic-config-cp)

[iKubernetes/servicemesh_in_practise Github](https://github.com/iKubernetes/servicemesh_in_practise)

