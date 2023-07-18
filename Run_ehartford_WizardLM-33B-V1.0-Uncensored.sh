#!/bin/bash

# Check if 'netstat' command is installed
if ! [ -x "$(command -v netstat)" ]; then
  echo "Error: 'netstat' is not installed." >&2
  exit 1
fi

# Function to find next available port
function next_available_port() {
  local port=$1
  while netstat -tuln | awk "{print \$4}" | grep -q ":$port"; do
    port=$(($port+1))
  done
  echo "$port"
}

# Get script name, remove suffix .sh
script_name=$(basename $0 .sh)
# Get container name after 'Run_' and replace '-' with '_'
container_name=$(echo $script_name | sed 's/^Run_//' | tr '-' '_')
# Get model name. Replacing _ with /
model_name=$(echo $script_name | awk -F "_" '{print $2 "/" $3}')

# Define variables
num_shard=`nvidia-smi -L | wc -l` # number of GPUs
volume=$PWD/data # share a volume with the Docker container to avoid downloading weights every run
shm_size=1g
start_port=8080
# Find next available port starting from $start_port
port=$(next_available_port $start_port)

# Check if the Docker container with the same name exists, if yes then stop and remove it
if [ $(docker ps -aq -f name=$container_name) ]; then
    echo "A Docker container with the name $container_name already exists. Stopping and removing it before continuing..."
    docker stop $container_name
    docker rm $container_name
fi

# Run Docker container in the background
docker run -d --name $container_name --gpus all --shm-size $shm_size -p $port:80 -v $volume:/data ghcr.io/huggingface/text-generation-inference:0.9 --model-id $model_name --num-shard $num_shard
