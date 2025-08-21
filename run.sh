#!/bin/bash
# run.sh
if [ "$2" = "build_script" ]; then
    echo "running............"
    PUBLIC_IP=$(cat /tmp/ec2_ip.txt)
    SSH_KEY="/usr/gitlab-runner/scripts/test.pem"
    cat > /tmp/build_and_deploy.sh <<EOF
#!/bin/bash
#JAVA
export JAVA_HOME=/usr/local/java/jdk23
export PATH="\$PATH":"\$JAVA_HOME"/bin
export CLASSPATH=.:"\$JAVA_HOME"/lib/dt.jar:"\$JAVA_HOME"/lib/tools.jar
set -e
branch="$CUSTOM_ENV_CI_COMMIT_BRANCH"
PROJECT_DIR="$CUSTOM_ENV_CI_PROJECT_DIR"
project_name="$CUSTOM_ENV_CI_PROJECT_NAMESPACE"
CUSTOM_ENV_CI_URL="$CUSTOM_ENV_CI_REPOSITORY_URL"
repo_name="$CUSTOM_ENV_CI_PROJECT_NAME"
SCRIPT_SH="$1"
echo "=== GitLab CI Build Information ==="
echo "Branch: \$branch"
echo "Project_url: \$project_url"
echo "Project: \$project_name/\$repo_name"
echo "=================================="

echo "正在克隆代码仓库..."
echo "url  $CUSTOM_ENV_CI_URL"
rm -rf "\$PROJECT_DIR"
git clone --branch "\$branch" "\${CUSTOM_ENV_CI_URL}" "\$PROJECT_DIR"
echo "进入项目目录: \$PROJECT_DIR"
cd "\$PROJECT_DIR"

# 构建项目
echo "执行脚本 $SCRIPT_SH"
bash /root/script
EOF
    chmod +x /tmp/build_and_deploy.sh

# 将构建镜像所需环境变量也传到新建实例中
printenv > /tmp/product_env

    # 设置为 runner 可读（可选）
    chmod +x /tmp/product_env
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" $1 root@"$PUBLIC_IP":/root/script
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" /tmp/product_env root@"$PUBLIC_IP":/tmp/product_env
    # 将 build_and_deploy.sh 上传到 ECS 实例并执行
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" /tmp/build_and_deploy.sh root@"$PUBLIC_IP":/root/build_and_deploy.sh
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" -T root@"$PUBLIC_IP" 'nohup /root/build_and_deploy.sh &'
else
    echo "非build_script阶段,跳过"
fi