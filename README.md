# GitLab CI/CD 利用动态抢占式实例构建系统

🚀 利用阿里云抢占式实例（Spot Instance）实现低成本、高性能的 GitLab CI/CD 构建流水线。

## 项目简介

本项目通过 GitLab CI/CD 流水线动态调用阿里云 API 创建**抢占式实例（Spot Instance）**，在创建的实例中执行代码构建与部署任务。构建完成后自动释放实例，实现资源按需使用、成本极低的持续集成/持续部署方案。

> 适用于构建任务重、对服务器性能要求高，但希望控制基础设施成本的团队。

---
核心特点：**轻量 GitLab 服务 + 临时构建高性能实例 + 自定义 Runner 调度**
## 项目成果

原单台虚拟机成本
<img width="1578" height="656" alt="image" src="https://github.com/user-attachments/assets/c4757a76-2992-45d1-9596-729e605b61b4" />

一次CI所需成本在0.02块，即两分左右。（以一个月构建1000次为例：1000*0.025=25块钱，一年25*12=300块）。对比之前准备一台 4核8G 包年计费实例，成本下降到了**1/10**
<img width="1831" height="256" alt="image" src="https://github.com/user-attachments/assets/7e96b927-6a4a-4afa-89c6-2fb5a01bca5d" />

---

## 设计思路

传统的 GitLab Runner 需要长期运行在高配置服务器上，成本较高，并且当存在一些大型编译项目时，如果机器性能不足，会导致研发花费大量时间等待构建，浪费生命。本方案采用以下架构：

1. **GitLab CI 触发构建任务**
2. **Runner（轻量级）调用阿里云 SDK**
3. **动态创建一台抢占式 ECS 实例**
4. **在新实例中拉取代码、执行构建与部署**
5. **任务完成后自动销毁实例**

GitLab 本体服务器仅需承担调度职责，性能要求极低，所有繁重的构建任务由临时高性能实例完成。

---

## 核心优势

✅ **成本极低**：抢占式实例价格可低至按量付费实例的 10%~30%  
✅ **性能强劲**：可选择高配实例（如 8C16G、GPU 实例）快速完成构建  
✅ **弹性伸缩**：每次构建独立运行，避免资源争用  
✅ **自动化管理**：创建 → 构建 → 部署 → 销毁 全流程自动化  
✅ **轻量 GitLab 服务**：无需高配服务器运行 GitLab 和 Runner

---


## 环境构建方法
### 准备工作：
1. 一台用于搭建Gitlab和Gitlab-runner的实例
2. 阿里云中可以用来构建实例的镜像（docker，java23，gradle、kubectl）
3. 用于登录临时创建的实例的密钥对
### 具体实操：
1. 搭建GitLab和Gitlab-runner
  ```version: '3.8'
  services:
    gitlab:
      image: docker.1ms.run/gitlab/gitlab-ce:latest
      container_name: gitlab
      restart: always
      environment:
              GITLAB_OMNIBUS_CONFIG: |
                        external_url 'http://121.41.98.144:8668'
                                gitlab_rails['gitlab_shell_ssh_port'] = 6886
      ports:
        - "8443:443"
        - "8668:8668"
        - "6886:22"
      volumes:
        - /usr/gitlab/config:/etc/gitlab
        - /usr/gitlab/logs:/var/log/gitlab
        - /usr/gitlab/data:/var/opt/gitlab
      shm_size: 256m
    gitlab-runner:
      image: docker.1ms.run/gitlab/gitlab-runner:latest
      container_name: gitlab-runner
      restart: always
      volumes:
        - /usr/gitlab-runner/config:/etc/gitlab-runner
        - /usr/gitlab-runner/script:/usr/gitlab-runner/scripts
        - /var/run/docker.sock:/var/run/docker.sock
      depends_on:
        - gitlab
```
2. 在gitlab-runner中注册runner（执行器选定custom自定义执行器）
   配置后的runner配置如下：<img width="1025" height="808" alt="image" src="https://github.com/user-attachments/assets/69da7b06-2c19-4f58-a5af-18d4167d7627" />
   **按照上图所示将项目中相关文件放到指定文件夹下。**
3. 项目中脚本主要功能
```
   prepare.sh： 创建ecs实例
   
   run.sh：具体业务逻辑
   
   cleanup.sh：删除创建的ecs实例
```   
5. .gitlab-ci.yml配置样例
   
   <img width="711" height="764" alt="image" src="https://github.com/user-attachments/assets/0250dd46-c999-4720-998c-563274b644bf" />
6. 按照上述配置完毕之后，触发流水线构建即可。

---


💡 **用更少的成本，跑更快的构建！**
