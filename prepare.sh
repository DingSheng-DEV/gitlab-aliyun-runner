#!/bin/bash

# 需要提前准备：安全组、镜像、交换机、密钥对

# 环境预装jq  aliyun

# ecs镜像预装  nfs-common、docker

# 配置变量
ALIYUN_REGION="$CUSTOM_ENV_ALIYUN_REGION"          # 阿里云区域
IMAGE_ID="$CUSTOM_ENV_IMAGE_ID"  # 镜像 ID
INSTANCE_TYPE="$CUSTOM_ENV_INSTANCE_TYPE"         # 实例类型
SECURITY_GROUP_ID="$CUSTOM_ENV_SECURITY_GROUP_ID"  # 安全组 ID
VSWITCH_ID="$CUSTOM_ENV_VSWITCH_ID"       # 虚拟交换机 ID
KEY_PAIR_NAME="$CUSTOM_ENV_KEY_PAIR_NAME" # SSH 密钥对名称
SSH_KEY="$CUSTOM_ENV_SSH_KEY"                 # SSH 私钥文件地址
AK="$CUSTOM_ENV_AK"
SK="$CUSTOM_ENV_SK"

#PUBLIC_IP="8.152.213.250"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY -T  root@$PUBLIC_IP 'date'
#
#exit
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
echo "Creating ECS instance..."
result=$(aliyun ecs CreateInstance \
    --RegionId $ALIYUN_REGION \
    --ImageId $IMAGE_ID \
    --InstanceType $INSTANCE_TYPE \
    --SecurityGroupId $SECURITY_GROUP_ID \
    --VSwitchId $VSWITCH_ID \
    --InternetMaxBandwidthOut 10 \
    --KeyPairName $KEY_PAIR_NAME
    )
INSTANCE_ID=$(echo "$result" | jq -r '.InstanceId')
echo "ECS Instance ID: $INSTANCE_ID"


echo "等待创建"
while true; do
    STATUS=$(aliyun ecs DescribeInstances --InstanceIds "[\"$INSTANCE_ID\"]"  )
    echo $STATUS
    STATUS=$(echo $STATUS | jq -r ".Instances.Instance[0].Status")
    echo $STATUS
    if [ "$STATUS" == "Stopped" ]; then
        break
    fi
    sleep 1
done

echo "分配公网ip"
res=$(aliyun ecs AllocatePublicIpAddress --InstanceId $INSTANCE_ID)
PUBLIC_IP=$(echo "$res" | jq -r ".IpAddress")
echo $PUBLIC_IP

# 启动 ECS 实例
echo "Starting ECS instance..."
res=$(aliyun ecs StartInstance --InstanceId $INSTANCE_ID)

# 等待实例启动
echo "等待实例启动"
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
    echo "Retrying in 1 seconds..."
    sleep 1
done

echo "执行构建命令"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY -T  root@$PUBLIC_IP <<EOF
  date
EOF

echo "$PUBLIC_IP" > /tmp/ec2_ip.txt
echo "$INSTANCE_ID" > /tmp/INSTANCE_ID.txt

# # 删除 ECS 实例（可选）
# echo "删除ecs"
# aliyun ecs DeleteInstance --InstanceId $INSTANCE_ID --Force true


echo "执行完毕"