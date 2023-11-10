#!/bin/bash

set -xe

pushd ~/fabric-samples/test-network

    # 준비물 organization 디렉토리내 id들, 제네시스블록, 채널-앵커트랜젝션, 컨테이너, 도커네트워크, 체인코드이미지 삭제
    ./network.sh down

popd

# 추가 정리부분