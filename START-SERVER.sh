#!/bin/bash


systemctl --user restart docker-desktop
for i in $(seq 10 -1 1); do
    echo "Docker is starting... $i seconds remaining"
    sleep 1
done
echo  "\nWait time of 10 seconds is over. Proceeding..."

cd Desktop/dmo-scalextric
docker-compose up

for i in $(seq 10 -1 1); do
    echo "Server is starting... $i seconds remaining"
    sleep 1
done
echo  "\nWait time of 10 seconds is over. Proceeding..."

$SHELl