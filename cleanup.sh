#!/bin/bash
# cleanup.sh
INSTANCE_ID=$(cat /tmp/INSTANCE_ID.txt)
# # 删除 ECS 实例（可选）
echo "删除ecs"
aliyun ecs DeleteInstance --InstanceId $INSTANCE_ID --Force true
echo "删除完毕"