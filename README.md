# neardo-project

# 선행조건
- 깨끗한 docker 환경
```
docker ps -a
docker network ls
docker volume ls
docker images dev-*

docker rm -f $(docker ps -aq)
docker rmi -f $(docker images dev-* -q)
docker network prune
docker volume prune
```

# 네트워크 시작 (3가지 버전 중 network ) 기관 3개 채널2개 - chickenchannel, eggchannel 
```
cd network
bash startnetwork.sh
```
# 체널 구성
```
bash createchannel.sh
```

# org2 - 3  ( eggchannel anchor peer update)
```
bash setAnchorPeerUpdate.sh
```

# 체인코드 배포 
```
bash deploy.sh
```

