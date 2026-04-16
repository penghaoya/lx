# kkFileView loong64 构建仓库

这个仓库现在按 `Loongson-Cloud-Community/docker-library` 里 `kekingcn/kkFileView/4.4.0` 的思路重构成了源码驱动流程：

- `Makefile` 统一负责源码拉取、补丁应用、镜像构建、冒烟测试和导出 tar
- `Dockerfile.loong64` 改成多阶段构建，直接在 loong64 容器内完成 Maven 打包
- GitHub Actions 只调用 `make export`，不再在工作流里手写 jar 下载和源码编译步骤

## 文件结构

- `Dockerfile.loong64`：多阶段 loong64 镜像构建
- `Makefile`：统一构建入口
- `switch_office_preview_type.patch`：沿用参考仓库思路，将 Office 预览默认类型切到 `pdf`
- `.github/workflows/build-kkfileview-loong64.yml`：GitHub Actions 构建并导出离线镜像
- `.github/workflows/export-loongnix-image.yml`：额外提供现成 loong64 镜像导出 tar 的能力

## 本地构建

构建 loong64 镜像：

```bash
make image TAG=4.4.0
```

构建后做基础冒烟测试：

```bash
make smoke TAG=4.4.0
```

导出离线部署 tar：

```bash
make export TAG=4.4.0
```

默认会生成类似下面的本地镜像和 tar：

```text
kkfileview:loong64-4.4.0
kkfileview-loong64-4.4.0.tar
```

如果需要覆盖运行时基础镜像或 LibreOffice 包，可以这样传参：

```bash
make export \
  TAG=4.4.0 \
  BASE_IMAGE=cr.loongnix.cn/library/openjdk:8-buster \
  OFFICE_PACKAGES="libreoffice-core libreoffice-writer libreoffice-calc libreoffice-impress"
```

如果需要推送镜像到仓库：

```bash
make push \
  TAG=4.4.0 \
  REGISTRY=lcr.loongnix.cn \
  ORGANIZATION=kekingcn \
  REPOSITORY=kkfileview
```

## GitHub Actions

手动运行 `Build kkFileView loong64 image` 工作流时，主要输入参数有：

- `kkfileview_version`：例如 `4.4.0` 或 `v4.4.0`
- `base_image`：运行时基础镜像
- `office_packages`：可选，覆盖 LibreOffice 安装包
- `image_name`：本地产出镜像名和 tar 文件名前缀

工作流内部会：

1. 规范化版本号
2. 调用 `make export`
3. 上传 `docker save` 生成的 tar 作为 Artifact

## 离线部署

将产物拷到龙芯服务器后执行：

```bash
docker load -i kkfileview-loong64-4.4.0.tar
docker run -d --name kkfileview -p 8012:8012 kkfileview:loong64-4.4.0
```

如果宿主机字体较全，建议额外挂载字体目录：

```bash
docker run -d \
  --name kkfileview \
  -p 8012:8012 \
  -v /usr/share/fonts:/usr/share/fonts \
  kkfileview:loong64-4.4.0
```

## 说明

- 参考仓库是源码构建模式，所以这里移除了原来 workflow 中 `release/source` 双分支逻辑
- 版本升级时通常只需要改 `TAG`，或者在 Actions 输入新版本
- 构建过程中会自动拉取上游 `https://github.com/kekingcn/kkFileView.git` 对应 tag 源码并应用本地 patch
