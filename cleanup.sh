#!/bin/bash
# cleanup.sh
IFS=':' read -r instance_id public_ip  <<< $(cat /tmp/runner_$CUSTOM_ENV_CI_PIPELINE_ID_$CUSTOM_ENV_CI_JOB_ID_$CUSTOM_ENV_CI_JOB_NAME.txt)
# # 删除 ECS 实例（可选）
echo "删除ecs"
aliyun ecs DeleteInstance --InstanceId $instance_id --Force true
echo "删除完毕"