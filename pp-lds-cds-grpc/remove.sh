docker stop pp-webserver1
docker stop pp-webserver1-sidecar
docker stop pp-webserver2
docker stop pp-webserver2-sidecar
docker stop pp-front-proxy-envoy
docker stop pp-xds-server
docker rm -v pp-webserver1
docker rm -v pp-webserver1-sidecar
docker rm -v pp-webserver2
docker rm -v pp-webserver2-sidecar
docker rm -v pp-front-proxy-envoy
docker rm -v pp-xds-server


