docker-compose -f docker-compose.yaml down -v

docker rmi -f $(docker images dev-* -q)

rm -rf ./config/*

rm -rf ./organizations/peerOrganizations
rm -rf ./organizations/ordererOrganizations

rm -f ./connection-org1.json
rm -f ./connection-org2.json

sudo rm -rf ./organizations/fabric-ca/org1/*
sudo rm -rf ./organizations/fabric-ca/org2/*
sudo rm -rf ./organizations/fabric-ca/org3/*
sudo rm -rf ./organizations/fabric-ca/ordererOrg/*

rm -rf ../application/config/*
rm -rf ../application/wallet/*
