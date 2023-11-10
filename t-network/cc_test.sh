#!/bin/bash

set -xe 

pushd ~/fabric-samples/test-network

    # peer 명령을 사용하기 위한 환경변수 세팅
    # 쉘스크립트 포함
    . scripts/envVar.sh

    export FABRIC_CFG_PATH=../config

    # org1 기관으로 연결하는 정보 환경변수 세팅
    setGlobals 1

    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA  --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA -C mychannel -n egg -c '{"Args":["RegisterEgg", "C001","E002","20231109","3","bstudent" ]}'

    sleep 3

    peer chaincode query -C mychannel -n egg -c '{"Args":["QueryEgg","E002"]}'

    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA  --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA -C mychannel -n egg -c '{"Args":["RequestShip","E002","Suwon Youngtonggu" ]}'

    sleep 3

    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA  --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA -C mychannel -n egg -c '{"Args":["ShipEgg","E002"]}'

    sleep 3

    # [ {Txid, timestamp, record, isdelete}....]
    peer chaincode query -C mychannel -n egg -c '{"Args":["QueryEggHistory","E002"]}'

popd