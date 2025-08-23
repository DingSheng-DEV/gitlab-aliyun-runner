#!/bin/bash

# 阿里云需要提前准备：安全组、镜像、交换机、密钥对

# ecs镜像预装  nfs-common、docker、git
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/.env

# 配置变量
IMAGE_ID="$CUSTOM_ENV_IMAGE_ID"  # 镜像 ID
INSTANCE_TYPE="$CUSTOM_ENV_INSTANCE_TYPE"         # 实例类型

#PUBLIC_IP="8.152.213.250"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY -T  root@$PUBLIC_IP 'date'

# 安装jq
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    apt update && apt install -y sudo jq
    echo "jq installed"
else
    echo "jq is already installed"
fi
# 安装nc
if ! command -v nc &> /dev/null; then
    echo "Installing nc..."
    apt install -y netcat-openbsd
    echo "nc installed"
else
    echo "nc is already installed"
fi
# 安装阿里云 CLI
if ! command -v aliyun &> /dev/null; then
    echo "Installing Alibaba Cloud CLI..."
    curl -O https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz
    tar xzvf aliyun-cli-linux-latest-amd64.tgz
    sudo mv aliyun /usr/local/bin/
    rm aliyun-cli-linux-latest-amd64.tgz
    echo "Aliyun CLI installed."
else
    echo "Aliyun CLI is already installed."
fi

# 配置阿里云 CLI
aliyun configure set --profile default --access-key-id $AK --access-key-secret $SK --region $ALIYUN_REGION

# 创建 ECS 实例
echo "创建ECS实例..."
result=$(aliyun ecs CreateInstance \
    --RegionId $ALIYUN_REGION \
    --ImageId $IMAGE_ID \
    --InstanceType $INSTANCE_TYPE \
    --SecurityGroupId $SECURITY_GROUP_ID \
    --VSwitchId $VSWITCH_ID \
    --InternetMaxBandwidthOut 10 \
    --KeyPairName $KEY_PAIR_NAME \
    --SpotStrategy "SpotAsPriceGo"
    )
INSTANCE_ID=$(echo "$result" | jq -r '.InstanceId')
echo "ECS实例ID: $INSTANCE_ID"


echo "等待创建..."
while true; do
    STATUS=$(aliyun ecs DescribeInstances --InstanceIds "[\"$INSTANCE_ID\"]"  )
#    echo $STATUS
    STATUS=$(echo $STATUS | jq -r ".Instances.Instance[0].Status")
#    echo $STATUS
    if [ "$STATUS" == "Stopped" ]; then
        break
    fi
    sleep 1
done

echo "分配公网ip"
res=$(aliyun ecs AllocatePublicIpAddress --InstanceId $INSTANCE_ID)
PUBLIC_IP=$(echo "$res" | jq -r ".IpAddress")
echo $PUBLIC_IP

# Todo 根据条件判断，是否直接从内网IP连接
# Todo 阿里云上架一个镜像

# 启动 ECS 实例
echo "启动ECS实例"
res=$(aliyun ecs StartInstance --InstanceId $INSTANCE_ID)

# 等待实例启动
echo "等待实例启动..."
#while true; do
#    res=$(aliyun ecs DescribeInstances --InstanceIds "[\"$INSTANCE_ID\"]"  )
#
#    STATUS=$(echo $res | jq -r ".Instances.Instance[0].Status")
#    if [ "$STATUS" == "Running" ]; then
#        break
#    fi
#    sleep 1
#done

# 持续测试端口
while ! nc -zv -w 1 "$PUBLIC_IP" "22"; do
    echo "1秒后重试连接..."
    sleep 1
done


echo "设置自动释放"
echo $ALIYUN_REGION $INSTANCE_ID
aliyun ecs ModifyInstanceAutoReleaseTime --region $ALIYUN_REGION  --RegionId "$ALIYUN_REGION" --InstanceId "$INSTANCE_ID" --AutoReleaseTime $(date -u -d "+31 minutes" +"%Y-%m-%dT%H:%M:%S"Z)

echo "$INSTANCE_ID:$PUBLIC_IP" > /tmp/runner_$CUSTOM_ENV_CI_PIPELINE_ID_$CUSTOM_ENV_CI_JOB_ID_$CUSTOM_ENV_CI_JOB_NAME.txt

echo "创建完毕"