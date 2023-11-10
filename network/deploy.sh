#!/bin/bash

VER=1.0
SEQ=1

set -ex 

NET_DIR=${PWD}
export FABRIC_CFG_PATH=${PWD}

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${NET_DIR}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${NET_DIR}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${NET_DIR}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${NET_DIR}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt

# 환경변수 설정함수
setEnv() {
    ORG=$1
    if [ $ORG -eq 2 ]; then 
        export CORE_PEER_LOCALMSPID="Org2MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
        export CORE_PEER_MSPCONFIGPATH=${NET_DIR}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
        export CORE_PEER_ADDRESS=localhost:9051
    else
        export CORE_PEER_LOCALMSPID="Org3MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
        export CORE_PEER_MSPCONFIGPATH=${NET_DIR}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
        export CORE_PEER_ADDRESS=localhost:10051
    fi 
}

CHANNEL_NAME=eggchannel

# package 명령
peer lifecycle chaincode package egg.tar.gz --path ../contract/egg --lang golang --label egg_$VER

# org1 설치 명령
setEnv 2
peer lifecycle chaincode install egg.tar.gz

# org2 설치 명령
setEnv 3
peer lifecycle chaincode install egg.tar.gz

peer lifecycle chaincode queryinstalled > qresult.txt
PACKAGE_ID=$(sed -n "/egg_$VER/{s/^Package ID: //; s/, Label:.*$//; p;}" qresult.txt)

# org1 승인 명령
setEnv 2
peer lifecycle chaincode approveformyorg -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name egg --version $VER --package-id $PACKAGE_ID --sequence $SEQ

sleep 3

# org2 승인 명령
setEnv 3
peer lifecycle chaincode approveformyorg -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name egg --version $VER --package-id $PACKAGE_ID --sequence $SEQ

sleep 3

setEnv 2
# 배포 명령
peer lifecycle chaincode commit -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name egg --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_ORG3_CA --version $VER --sequence $SEQ

sleep 3

# TEST - TRANSFER
  peer chaincode invoke -o localhost:11050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA  --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_ORG3_CA -C ${CHANNEL_NAME} -n egg -c '{"Args":["RegisterEgg", "C001","E002","20231110","3","bstudent" ]}'

sleep 3

# TEST - GETALLASSET
    peer chaincode query -C ${CHANNEL_NAME} -n egg -c '{"Args":["QueryEgg","E002"]}'
