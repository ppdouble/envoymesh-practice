## Dynamic configuration (control plane) 


## Prepare

1. A container works as front proxy including envoy, bootstrap configuration and admin-interface
2. A container works as control plane which responses dynamic configuration to xds API
3. two container work as web server

## front proxy
### docker-compose configuration
```text
  proxy:
    build:
      context: .
      dockerfile: Dockerfile-proxy
    depends_on:
    - service1
    - service2
    ports:
    - 10000:10000
    - 19000:19000
```
#### ports
publish 10000 to client
publish 19000 for admin-interface

#### base image

`envoyproxy/envoy:v1.23.1` 

configuration file `/etc/envoy.yaml`

```text
FROM envoyproxy/envoy:v1.23.1

COPY ./envoy.yaml /etc/envoy.yaml
RUN chmod go+r /etc/envoy.yaml
CMD ["/usr/local/bin/envoy", "-c /etc/envoy.yaml"]
```
### envoy bootstrap configuration
#### envoy admin-interface
listen 19000

```text
admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 19000
```
#### envoy dynamic configuration

xds API request configuration to server `xds_cluster`

```text
dynamic_resources:
  ads_config:
    api_type: GRPC
    transport_api_version: V3
    grpc_services:
    - envoy_grpc:
        cluster_name: xds_cluster
  cds_config:
    resource_api_version: V3
    ads: {}
  lds_config:
    resource_api_version: V3
    ads: {}
```
#### the address of xds_cluster is go-control-plane with port 18000

```text
    name: xds_cluster
    load_assignment:
      cluster_name: xds_cluster
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: go-control-plane
                port_value: 18000
```
## the container works as xds API server (control plane)
### docker-compose configuration
```text
  go-control-plane:
    build:
      context: .
      dockerfile: Dockerfile-control-plane
    command: bin/example
    healthcheck:
      test: nc -zv localhost 18000
```

#### base image
golang:1.14

base program `https://github.com/envoyproxy/go-control-plane`, listen `18000`
modify `resource.go` to mock the change of envoy configuration

```go
const (
	ClusterName  = "example_proxy_cluster"
	RouteName    = "local_route"
	ListenerName = "listener_0"
	ListenerPort = 10000
	UpstreamHost = "service1"
	UpstreamPort = 8080
)
```

compile the program and put it into image

it will response configuration to xds API after running the image as a container

```text
FROM golang:1.14

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
    && apt-get -qq install --no-install-recommends -y netcat \
    && apt-get -qq autoremove -y \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

RUN git clone https://github.com/envoyproxy/go-control-plane && cd go-control-plane && git checkout b4adc3bb5fe5288bff01cd452dad418ef98c676e
ADD ./resource.go /go/go-control-plane/internal/example/resource.go
RUN cd go-control-plane && make bin/example
WORKDIR /go/go-control-plane
```

## two container work as web server
### docker-compose configuration
```text
  service1:
    build:
      context: ../shared/echo
    hostname: service1

  service2:
    build:
      context: ../shared/echo
    hostname: service2
```
#### base image
 `../shared/echo/Dockerfile` config `jmalloc/echo-server:0.3.3` as base image

[https://github.com/jmalloc/echo-server](https://github.com/jmalloc/echo-server)
## validation 
using `docker-compose up` to pull image, compile image and create container

### proxy validation
request `10000`  to envoy front proxy
```bash
$ curl http://localhost:10000
Request served by service1

HTTP/1.1 GET /

Host: localhost:10000
Accept: */*
User-Agent: curl/7.61.1
X-Envoy-Expected-Rq-Timeout-Ms: 15000
X-Forwarded-Proto: http
X-Request-Id: 386e43f0-0dee-4db5-b341-f25c3b0c51df
```

if you config multiple endpoints, and the load balance policy is setting as ROUND_ROBIN, you can try to `while sleep 1; do curl -i http://localhost:10000; done` to see whether load balance works well
### admin-interface validation
request `19000` to the container including envoy front proxy
```bash
$ curl -s http://localhost:19000/config_dump  | jq '.configs[1].dynamic_active_clusters[0].cluster.load_assignment.endpoints[0].lb_endpoints[0].endpoint.address.socket_address'
{
  "address": "service1",
  "port_value": 8080
}

```
### dynamic configuration validation
#### change upstream hosts
the upstream hosts configuration is fixed in go-control-plane. you should change the resourse.go and recompile go-control-plane to mock the change of envoy configuration. the envoy can reload the configuration dynamically withou being restart.

`resource.go`
```go
const (
	ClusterName  = "example_proxy_cluster"
	RouteName    = "local_route"
	ListenerName = "listener_0"
	ListenerPort = 10000
	UpstreamHost = "service2"
	UpstreamPort = 8080
)
```
#### see whether it is changed
```bash
$ curl -s http://localhost:19000/config_dump  | jq '.configs[1].dynamic_active_clusters[0].cluster.load_assignment.endpoints[0].lb_endpoints[0].endpoint.address.socket_address'
{
  "address": "service2",
  "port_value": 8080
}

```
#### proxy
```bash
$ curl http://localhost:10000
Request served by service2

HTTP/1.1 GET /

Host: localhost:10000
Accept: */*
User-Agent: curl/7.61.1
X-Envoy-Expected-Rq-Timeout-Ms: 15000
X-Forwarded-Proto: http
X-Request-Id: 7f2d1344-be24-4301-ae7d-f8c376ad1e13

```
## Ref
[Dynamic configuration (control plane)  Official DOC](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/dynamic-configuration-control-plane)

[dynamic-config-cp Github](https://github.com/envoyproxy/envoy/tree/main/examples/dynamic-config-cp)

To learn about this sandbox and for instructions on how to run it please head over
to the [Envoy docs](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/dynamic-configuration-control-plane.html).
