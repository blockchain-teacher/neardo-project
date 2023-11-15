#!/bin/bash

# 0. 초기화

# 1. 환경설정
export FABRIC_CFG_PATH=${PWD}

# 2. CA 컨테이너 수행 docker-compose.yaml ca_org1, ca_org2, ca_orderer 서비스 정의
docker-compose -f docker-compose.yaml up -d ca_org1 ca_org2 ca_org3 ca_orderer
sleep 5

# 3. identity 등록
. registerenroll.sh
echo "Create Org1 crypto material"
createOrg1
echo "Create Org2 crypto material"
createOrg2
echo "Create Org3 crypto material"
createOrg3
echo "Create Orderer crypto material"
createOrderer

# 4. genesis.block 생성 -> configtx.yaml
configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./config/genesis.block

# 5. PEER, ORDERER 컨테이너 수행
docker-compose -f docker-compose.yaml up -d orderer.example.com peer0.org1.example.com peer0.org2.example.com peer1.org2.example.com peer0.org3.example.com

sleep 5

# connection profile 생성
./ccp-generate.sh
cp connection-org2.json ../application/config


