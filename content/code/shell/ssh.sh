#!/bin/bash

rm -rf .ssh/known_hosts
rm -rf .ssh/known_hosts.old

remote_user="root"
target_ip="192.168.0.10"

echo "-------------------------------"
echo "$remote_user@$target_ip"
echo "-------------------------------"

ssh "$remote_user"@"$target_ip"
