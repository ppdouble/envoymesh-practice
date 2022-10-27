cd webserver1
docker-compose --file=webserver1-compose.yaml up -d
cd ..

cd webserver2
docker-compose --file=webserver2-compose.yaml up -d
cd ..

cd front-proxy
docker-compose --file=fp-compose.yaml up -d
cd ..

cd xds-server
docker-compose --file=xds-server-compose.yaml up -d
cd ..
