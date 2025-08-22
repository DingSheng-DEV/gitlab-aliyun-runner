#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/.env

IFS=':' read -r instance_id public_ip  <<< $(cat /tmp/runner_$CUSTOM_ENV_CI_PIPELINE_ID_$CUSTOM_ENV_CI_JOB_ID_$CUSTOM_ENV_CI_JOB_NAME.txt)

ssh_param="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY"
ssh_target=root@$public_ip

echo "当前运行阶段: $2"
case $2 in
    prepare_script)
      echo "尚未实现"
      exit 0
      ;;
    get_sources)
      # Todo clone地址兼容内网
      ssh $ssh_param -T $ssh_target "git clone --branch $CUSTOM_ENV_CI_COMMIT_BRANCH $CUSTOM_ENV_CI_REPOSITORY_URL $CUSTOM_ENV_CI_PROJECT_DIR && ls $CUSTOM_ENV_CI_PROJECT_DIR"

      ;;
    build_script)
      scp $ssh_param $1 $ssh_target:/tmp/script
      ssh $ssh_param -T $ssh_target "bash -ic 'cd $CUSTOM_ENV_CI_PROJECT_DIR && bash /tmp/script'"
      ;;
    *)
      echo "尚未实现"
      exit 0
      ;;
esac