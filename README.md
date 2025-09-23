# GitLab 阿里云弹性伸缩CI/CD脚本

🚀 利用阿里云抢占式实例（Spot Instance）实现低成本、高性能的 GitLab CI/CD 构建流水线。

## 项目背景
  GitLab 原生的自动伸缩功能目前仅支持 Amazon AWS、Google Cloud Platform 和 Microsoft Azure 云平台，尚未官方支持阿里云（Alibaba Cloud）。这在一定程度上限制了国内用户或阿里云生态用户高效集成 GitLab CI/CD 的能力。
本脚本项目旨在填补这一空白，为 GitLab 与阿里云的深度集成提供自动化支持。通过本方案，用户可便捷地在阿里云上实现项目存储管理及持续构建与部署，从而提升开发运维效率，降低云资源成本，打造更贴合本土云环境体验。
<img width="1462" height="950" alt="image" src="https://github.com/user-attachments/assets/e49daa88-cb78-445e-b7bf-1423fe9ba216" />

---
## 项目简介

本项目通过 GitLab CI/CD 流水线动态调用阿里云 API 创建**抢占式实例（Spot Instance）**，在创建的实例中执行代码构建与部署任务。构建完成后自动释放实例，实现资源按需使用、成本极低的持续集成/持续部署方案。

> 适用于构建任务重、对服务器性能要求高，但希望控制基础设施成本的团队。

核心特点：**轻量 GitLab 服务 + 临时构建高性能实例 + 自定义 Runner 调度**

---

## 工作流程

<img width="238" height="514" alt="image" src="https://github.com/user-attachments/assets/d4cd7a89-b1dd-44e7-8c7a-e4822092df77" />


> GitLab 本体服务器仅需承担调度职责，性能要求极低，所有繁重的构建任务由临时高性能实例完成。

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
1. 服务器：用于搭建Gitlab和Gitlab-runner基础环境
2. 阿里云镜像：用来构建实例的镜像（docker，java23，gradle、kubectl）
3. 密钥对：用于登录临时创建的实例
### 具体实操：
1. 搭建GitLab和Gitlab-runner完毕后，注册自定义执行器的runner：https://docs.gitlab.com/runner/register/
  搭建gitlab-runner时，需要挂载目录到启动的容器中，以便后续脚本的放置：  
<img width="381" height="59" alt="image" src="https://github.com/user-attachments/assets/d4bcd45e-7bfc-4e26-9f73-aa52ed921a51" />

2. 配置注册的runner

   配置后的runner配置详情如下：<img width="1025" height="808" alt="image" src="https://github.com/user-attachments/assets/69da7b06-2c19-4f58-a5af-18d4167d7627" />
   **按照上图所示将项目中相关文件放到指定文件夹下。**
3. 项目中脚本主要功能
```
   prepare.sh： 创建ecs实例
   
   run.sh：具体业务逻辑
   
   cleanup.sh：删除创建的ecs实例
```   
4. .gitlab-ci.yml配置样例
   
   <img width="710" height="763" alt="image" src="https://github.com/user-attachments/assets/cae4c06f-1619-437b-a072-1effd3ce1c09" />

5. 按照上述配置完毕之后，触发流水线构建即可。

---
## 实际运行效果

原单台虚拟机成本
<img width="1578" height="656" alt="image" src="https://github.com/user-attachments/assets/c4757a76-2992-45d1-9596-729e605b61b4" />

一次CI所需成本在0.02块，即两分左右。（以一个月构建1000次为例：1000*0.025=25块钱，一年25*12=300块）。对比之前准备一台 4核8G 包年计费实例，成本下降到了**1/10**
<img width="1831" height="256" alt="image" src="https://github.com/user-attachments/assets/7e96b927-6a4a-4afa-89c6-2fb5a01bca5d" />

---

💡 **用更少的成本，跑更快的构建！**
