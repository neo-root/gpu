#!/usr/bin/env bash
set -eo pipefail

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare ${param}="true"
  fi
  shift
done

if ! [ -x "$(command -v git)" ]; then
  echo -e "${RED}Error: git is not installed.${NC}" >&2
  echo -e "Aborting.${NC}" >&2
  exit 1
fi

if [ ! -z ${nopurge} ]; then
  echo -e "${YELLOW}Purging intermediate build products is disabled.${NC}"
fi

if [ ! -z ${nopull} ]; then
  echo -e "${YELLOW}Latest upstream image will not be force-pulled.${NC}"
fi

if [ ! -z ${nogpubuild} ]; then
  echo -e "${YELLOW}Image build for the gpuminer is disabled.${NC}"
fi

echo -e "${GREEN}Refreshing this Git repository...${NC}"
git pull
echo

if [ -z ${nogpubuild} ]; then
  echo -e "${GREEN}Rebuilding GPU miner sources... (this might take some time)${NC}"
  docker build --build-arg CACHEBUST=$(date +%s) -t local/gpuminer -f Dockerfile.gpuminer .
  echo
fi

if [ -z ${nopurge} ]; then
  echo -e "${GREEN}Removing intermediate build products...${NC}"
  docker image prune -f
  docker rmi nvidia/cuda:11.0-devel-ubuntu18.04
  echo
fi

if [ -z ${nopull} ]; then
  echo -e "${GREEN}Pulling latest upstream image...${NC}"
  docker lgray/bcnode:last
echo
fi

echo -e "${GREEN}Building new image...${NC}"
docker build -t lgray/bcnode:last -f Dockerfile.bcnode .
echo

if [ -z ${nopurge} ]; then
  echo -e "${GREEN}Removing original bcnode image...${NC}"
  docker rmi lgray/bcnode:last
  echo
fi

echo -e "${GREEN}Showing all locally available Docker images:${NC}"
docker images

echo -e "${GREEN}Done.${NC}"
