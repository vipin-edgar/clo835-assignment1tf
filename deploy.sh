#!/bin/bash

# Function to check if the last command was successful
check_command() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed!"
    exit 1
  fi
}

# Log in to AWS ECR
echo "Logging in to AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 011926502057.dkr.ecr.us-east-1.amazonaws.com
check_command "AWS ECR login"

# Pull the latest Docker images from ECR
echo "Pulling DB image from ECR..."
docker pull 011926502057.dkr.ecr.us-east-1.amazonaws.com/vipinecr/my_db:latest
check_command "Pulling DB image"

echo "Pulling App image from ECR..."
docker pull 011926502057.dkr.ecr.us-east-1.amazonaws.com/vipinecr/my_app:latest
check_command "Pulling App image"

# Check if the custom Docker network exists, if not create it
echo "Checking if custom Docker network exists..."
docker network ls | grep -q my_custom_network
if [ $? -ne 0 ]; then
  echo "Creating custom Docker network..."
  docker network create my_custom_network
  check_command "Creating Docker network"
else
  echo "Custom Docker network already exists. Skipping creation."
fi

# Run MySQL container
echo "Starting MySQL container..."
docker run -d --name mysql-container \
  --network my_custom_network \
  -e MYSQL_ROOT_PASSWORD=pw \
  011926502057.dkr.ecr.us-east-1.amazonaws.com/vipinecr/my_db:latest
check_command "Starting MySQL container"

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until docker exec mysql-container mysqladmin -u root -ppw --host="localhost" --silent ping; do
  echo "Waiting for MySQL to be ready..."
  sleep 10
done
echo "MySQL is ready."

# Run Blue app container
echo "Starting Blue app container..."
docker run -d -p 8081:8080 \
  --network my_custom_network \
  --name blue \
  -e DBHOST=mysql-container \
  -e DBPORT=3306 \
  -e DBUSER=root \
  -e DATABASE=employees \
  -e DBPWD=pw \
  -e APP_COLOR=blue \
  011926502057.dkr.ecr.us-east-1.amazonaws.com/vipinecr/my_app:latest
check_command "Starting Blue app container"

# Run Pink app container
echo "Starting Pink app container..."
docker run -d -p 8082:8080 \
  --network my_custom_network \
  --name pink \
  -e DBHOST=mysql-container \
  -e DBPORT=3306 \
  -e DBUSER=root \
  -e DATABASE=employees \
  -e DBPWD=pw \
  -e APP_COLOR=pink \
  011926502057.dkr.ecr.us-east-1.amazonaws.com/vipinecr/my_app:latest
check_command "Starting Pink app container"

# Run Lime app container
echo "Starting Lime app container..."
docker run -d -p 8083:8080 \
  --network my_custom_network \
  --name lime \
  -e DBHOST=mysql-container \
  -e DBPORT=3306 \
  -e DBUSER=root \
  -e DATABASE=employees \
  -e DBPWD=pw \
  -e APP_COLOR=lime \
  011926502057.dkr.ecr.us-east-1.amazonaws.com/vipinecr/my_app:latest
check_command "Starting Lime app container"

# Wait for  container to be ready

echo "Installing iputils-ping in Blue app container..."
docker exec -it blue sh -c "apt update && apt install -y iputils-ping"
check_command "Installing ping in Blue container"

echo "Installing iputils-ping in pink app container..."
docker exec -it pink sh -c "apt update && apt install -y iputils-ping"
check_command "Installing ping in Blue container"

echo "Installing iputils-ping in lime app container..."
docker exec -it lime sh -c "apt update && apt install -y iputils-ping"
check_command "Installing ping in Blue container"


echo "All containers started successfully!"


