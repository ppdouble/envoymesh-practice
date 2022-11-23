cd webserver1
docker-compose --file=webserver1-compose.yaml up -d
cd ..

cd webserver2
docker-compose --file=webserver2-compose.yaml up -d
cd ..

cd front-proxy
docker-compose --file=fp-compose.yaml up -d
cd ..

#cd xds-server
#docker-compose --file=xds-server-compose.yaml up -d
#cd ..


docker cp front-proxy/fp-envoy.yaml pp-front-proxy-envoy:/etc/envoy/envoy.yaml

docker cp webserver1/envoy-sidecar-proxy.yaml pp-webserver1-sidecar:/etc/envoy/envoy.yaml

docker cp webserver2/envoy-sidecar-proxy.yaml pp-webserver2-sidecar:/etc/envoy/envoy.yaml
