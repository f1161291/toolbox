#!/bin/bash
set -e

echo "================ Docker BuildX 多架构构建工具 ================"
read -p "请输入DockerHub用户名(仓库名): " DOCKER_HUB_USER
read -p "请输入镜像名称: " IMAGE_NAME
read -p "请输入镜像标签 [默认latest]: " IMAGE_TAG
# 默认值处理
IMAGE_TAG=${IMAGE_TAG:-latest}

PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"

echo ""
echo "===== 确认信息 ====="
echo "仓库账号:  $DOCKER_HUB_USER"
echo "镜像名称:  $IMAGE_NAME"
echo "镜像标签:  $IMAGE_TAG"
echo "目标平台:  $PLATFORMS"
read -p "确认开始构建推送？(y/N): " CONFIRM
if [[ ! "${CONFIRM,,}" == "y" ]];then
    echo "已退出"
    exit 0
fi

# 安装qemu，仅首次会实际安装
echo -e "\n>>> 检查安装 qemu-user-static"
apt update -y
apt install -y qemu-user-static

# 创建buildx构建器
if ! docker buildx ls | grep -q multi-builder;then
    docker buildx create --name multi-builder
fi
docker buildx use multi-builder
docker buildx inspect --bootstrap

FULL_IMAGE="${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
echo -e "\n>>> 开始构建 & 推送镜像: $FULL_IMAGE"

docker buildx build \
  --platform ${PLATFORMS} \
  -t "${FULL_IMAGE}" \
  --push .

echo -e "\n✅ 构建推送完成！"
echo "校验命令:"
echo "docker manifest inspect ${FULL_IMAGE}"
