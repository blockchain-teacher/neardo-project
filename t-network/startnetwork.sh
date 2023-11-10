#!/bin/bash

# 쉘스크립트 디버깅설정
set -xe

# 디렉토리 스택구조 활용
pushd ~/fabric-samples/test-network

    # peer 명령을 사용하기 위한 환경변수 설정

    export FABRIC_CFG_PATH=../config
    
    # 네트워크 시작+채널구성 ( 생성 - 조인 - 앵커업데이트 )
    ./network.sh up createChannel -ca -c eggchannel
    
    # 체인코드 배포 작업 ( 패키지 - 설치 - 승인 - 커밋 )
    ./network.sh deployCC -ccn egg -ccp ~/dev/neardo-project/contract/egg -ccl go -ccv 1.0 -c eggchannel

popd

