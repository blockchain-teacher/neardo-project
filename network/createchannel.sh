#!/bin/bash

export FABRIC_CFG_PATH=${PWD}
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

CHANNEL_NAME="chickenchannel"

function setOrg() {
    ORG=$1
    CHNAME=$2

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID=Org${ORG}MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org${ORG}.example.com/peers/peer0.org${ORG}.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org${ORG}.example.com/users/Admin@org${ORG}.example.com/msp
 
    if [ ${ORG} -eq 1 ]; then
        export CORE_PEER_ADDRESS=localhost:7051
    elif [ ${ORG} -eq 2 ]; then
        export CORE_PEER_ADDRESS=localhost:8051
    elif [ ${ORG} -eq 3 ]; then
        export CORE_PEER_ADDRESS=localhost:10051
    fi

    if [ "${CHNAME}" == "eggchannel" ] && [ ${ORG} -eq 2 ]; then
        export CORE_PEER_ADDRESS=localhost:9051
    fi

}
# configtxgen 유틸리티를 사용해서 채널 트랜젝션 생성, 앵커트랜젝션 생성
configtxgen -profile ChickenOrgsChannel -outputCreateChannelTx ./config/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

setOrg 1
# peer channel create 명령
peer channel create -o localhost:11050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./config/${CHANNEL_NAME}.tx --outputBlock ./config/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA

sleep 3

# org1 peer 에 연결 환경설정
# peer channel join
peer channel join -b ./config/${CHANNEL_NAME}.block

# org2 peer 에 연결 환경설정
setOrg 2

# peer channel join
peer channel join -b ./config/${CHANNEL_NAME}.block

# org1 peer 에 연결 환경설정
setOrg 1

# org1 anchor피어 tx 생성 -> configtxgen
configtxgen -profile ChickenOrgsChannel -outputAnchorPeersUpdate ./config/ChickenOrg1MSPAnchor.tx -channelID ${CHANNEL_NAME} -asOrg Org1MSP

# org1 의 앵커 설정 : peer channel update
peer channel update -f ./config/ChickenOrg1MSPAnchor.tx -c ${CHANNEL_NAME} -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA


CHANNEL_NAME=eggchannel

# configtxgen 유틸리티를 사용해서 채널 트랜젝션 생성, 앵커트랜젝션 생성
configtxgen -profile EggOrgsChannel -outputCreateChannelTx ./config/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

setOrg 2 eggchannel

echo $CORE_PEER_ADDRESS

# peer channel create 명령
peer channel create -o localhost:11050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./config/${CHANNEL_NAME}.tx --outputBlock ./config/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA

sleep 3

# org1 peer 에 연결 환경설정
# peer channel join
peer channel join -b ./config/${CHANNEL_NAME}.block

# org2 peer 에 연결 환경설정
setOrg 3

# peer channel join
peer channel join -b ./config/${CHANNEL_NAME}.block

peer channel list

# org2 peer 에 연결 환경설정
setOrg 2

# org2 anchor피어 tx 생성 -> configtxgen
configtxgen -profile EggOrgsChannel -outputAnchorPeersUpdate ./config/EggOrg2MSPAnchor.tx -channelID ${CHANNEL_NAME} -asOrg Org2MSP

# org2 의 앵커 설정 : peer channel update
peer channel update -f ./config/EggOrg2MSPAnchor.tx -c ${CHANNEL_NAME} -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

# org3 peer 에 연결 환경설정
setOrg 3

# org3 anchor피어 tx 생성 -> configtxgen
configtxgen -profile EggOrgsChannel -outputAnchorPeersUpdate ./config/EggOrg3MSPAnchor.tx -channelID ${CHANNEL_NAME} -asOrg Org3MSP

# org3 의 앵커 설정 : peer channel update
peer channel update -f ./config/EggOrg3MSPAnchor.tx -c ${CHANNEL_NAME} -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA

sleep 2
# connection profile 구성