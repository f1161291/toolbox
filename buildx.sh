#!/bin/bash
set -euo pipefail

echo "================ Docker BuildX 多架构构建工具 ================"

# ---------- 前置环境检查 ----------
command -v docker >/dev/null 2>&1 || { echo "❌ 未检测到 docker 命令"; exit 1; }
docker buildx version >/dev/null 2>&1 || { echo "❌ 未安装 docker buildx 插件"; exit 1; }
[[ -f ./Dockerfile ]] || { echo "❌ 当前目录 ($(pwd)) 下没有 Dockerfile"; exit 1; }

# ---------- 交互输入 ----------
read -rp "请输入 DockerHub 用户名/组织: " DOCKER_HUB_USER || { echo "已取消"; exit 1; }
read -rp "请输入镜像名称: " IMAGE_NAME || { echo "已取消"; exit 1; }
read -rp "请输入镜像标签 [默认 latest]: " IMAGE_TAG || { echo "已取消"; exit 1; }
IMAGE_TAG=${IMAGE_TAG:-latest}

read -rp "请输入目标平台 [默认 linux/amd64,linux/arm64,linux/arm/v7]: " PLATFORMS || true
PLATFORMS=${PLATFORMS:-linux/amd64,linux/arm64,linux/arm/v7}

# ---------- 输入校验 ----------
[[ -n "${DOCKER_HUB_USER}" && -n "${IMAGE_NAME}" ]] || { echo "❌ 用户名/镜像名不能为空"; exit 1; }

BUILDER_NAME="multi-builder"
FULL_IMAGE="${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo "===== 确认信息 ====="
echo "仓库账号:  ${DOCKER_HUB_USER}"
echo "镜像名称:  ${IMAGE_NAME}"
echo "镜像标签:  ${IMAGE_TAG}"
echo "目标平台:  ${PLATFORMS}"
echo "完整镜像:  ${FULL_IMAGE}"
read -rp "确认开始构建推送？(y/N): " CONFIRM || CONFIRM=""
if [[ ! "${CONFIRM,,}" == "y" ]]; then
    echo "已退出"
    exit 0
fi

# ---------- Docker 登录检查 ----------
if ! grep -q '"auths"' "${HOME}/.docker/config.json" 2>/dev/null; then
    echo "⚠️ 未检测到 docker 登录信息，--push 可能失败，请先执行 docker login"
fi

# ---------- 注册 QEMU binfmt（多架构必需） ----------
echo -e "\n>>> 注册 QEMU binfmt"
if ! docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null 2>&1; then
    echo "⚠️ tonistiigi/binfmt 注册失败，尝试 apt 安装 qemu-user-static"
    if [[ $EUID -eq 0 ]]; then
        apt-get update -y
        apt-get install -y qemu-user-static
    else
        echo "⚠️ 当前非 root 用户，无法通过 apt 安装，多架构构建可能失败"
    fi
fi

# ---------- 准备 buildx builder ----------
echo -e "\n>>> 准备 buildx builder: ${BUILDER_NAME}"
if ! docker buildx inspect "${BUILDER_NAME}" >/dev/null 2>&1; then
    docker buildx create --name "${BUILDER_NAME}" --driver docker-container
fi
docker buildx inspect "${BUILDER_NAME}" --bootstrap >/dev/null

# ---------- 构建并推送 ----------
echo -e "\n>>> 开始构建 & 推送镜像: ${FULL_IMAGE}"
docker buildx build \
  --builder "${BUILDER_NAME}" \
  --platform "${PLATFORMS}" \
  -t "${FULL_IMAGE}" \
  --push .

# ---------- 校验 ----------
echo -e "\n>>> 校验 manifest"
if docker manifest inspect "${FULL_IMAGE}" >/dev/null 2>&1; then
    echo "✅ 构建推送完成，manifest 校验通过！"
    echo "镜像: ${FULL_IMAGE}"
else
    echo "⚠️ 推送完成，但 manifest 校验失败，请手动执行:"
    echo "  docker manifest inspect ${FULL_IMAGE}"
fi
