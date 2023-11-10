#!/bin/bash

set -xe

pushd ~/dev/BS22_class-examples/basic-network-ca

    ./startnetwork.sh
    sleep 5

    ./createchannel.sh
    
    sleep 5

    ./setAnchorPeerUpdate.sh

    sleep 5
    
    ./deployCC.sh

popd

