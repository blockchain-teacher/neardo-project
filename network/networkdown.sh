docker-compose -f docker-compose.yaml down -v

rm -rf ./config/*

rm -rf ./organizations/peerOrganizations
rm -rf ./organizations/ordererOrganizations

rm -f ./connection-org1.json

sudo rm -rf ./organizations/fabric-ca/*