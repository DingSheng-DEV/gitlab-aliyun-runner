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

      IFS=',' read -ra cache_dirs <<< $CUSTOM_ENV_CACHE_DIRS
      for item in "${cache_dirs[@]}"; do
         file_name="$BUILD_CACHE_DIR/$CUSTOM_ENV_CI_PROJECT_ID-${item//\//-}.tar"
         echo $file_name
         cmd="bash -ic '[ -f '$file_name' ] && rm -rf $item && mkdir -p $item && echo 'hit' && tar -xf $file_name -C $item  && ls $item'"
         echo $cmd

         ssh $ssh_param -T $ssh_target $cmd
      done

      ssh $ssh_param -T $ssh_target "bash -ic 'service docker restart'"

      scp $ssh_param $1 $ssh_target:/tmp/script
      ssh $ssh_param -T $ssh_target "bash -ic 'cd $CUSTOM_ENV_CI_PROJECT_DIR && bash /tmp/script'"

      IFS=',' read -ra cache_dirs <<< $CUSTOM_ENV_CACHE_DIRS
      for item in "${cache_dirs[@]}"; do
         file_name="$BUILD_CACHE_DIR/$CUSTOM_ENV_CI_PROJECT_ID-${item//\//-}.tar"
         echo $file_name

         cmd="bash -ic 'tar -cf $file_name -C $item ./'"
         echo $cmd

         ssh $ssh_param -T $ssh_target $cmd
      done

      ;;
    *)
      echo "尚未实现"
      exit 0
      ;;
esac