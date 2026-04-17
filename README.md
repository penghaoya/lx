# kkFileView loong64 构建仓库

这个仓库现在按 `Loongson-Cloud-Community/docker-library` 里 `kekingcn/kkFileView/4.4.0` 的思路重构成了源码驱动流程：

- `Makefile` 统一负责源码拉取、补丁应用、镜像构建、冒烟测试和导出 tar
- `Dockerfile.loong64` 改成多阶段构建，默认在 loong64 容器内完成 Maven 打包，也支持直接下载 release jar
- GitHub Actions 统一调用 `make export`，用参数切换源码构建或 jar 下载模式

## 文件结构

- `Dockerfile.loong64`：多阶段 loong64 镜像构建
- `Makefile`：统一构建入口
- `switch_office_preview_type.patch`：沿用参考仓库思路，将 Office 预览默认类型切到 `pdf`
- `.github/workflows/build-kkfileview-jar.yml`：GitHub Actions 构建 kkFileView jar 并上传 Artifact
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

如果想跳过源码编译，直接下载发布好的 jar 来构建镜像：

```bash
make export \
  TAG=4.4.0 \
  BUILD_MODE=release
```

默认会尝试下载：

```text
https://github.com/kekingcn/kkFileView/releases/download/v4.4.0/kkFileView-4.4.0.jar
```

如果你需要改成私有制品库或自定义下载地址，可以覆盖：

```bash
make export \
  TAG=4.4.0 \
  BUILD_MODE=release \
  RELEASE_JAR_URL="https://your-mirror.example.com/kkFileView-4.4.0.jar"
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
- `build_mode`：`source` 表示源码构建，`release` 表示直接下载 jar
- `release_jar_url`：可选，自定义 jar 下载地址；为空时按默认 GitHub release 地址拼接
- `base_image`：运行时基础镜像
- `office_packages`：可选，覆盖 LibreOffice 安装包
- `image_name`：本地产出镜像名和 tar 文件名前缀

工作流内部会：

1. 规范化版本号
2. 调用 `make export`
3. 上传 `docker save` 生成的 tar 作为 Artifact

如果你只想要可下载的 jar，可以手动运行 `Build kkFileView jar` 工作流：

- `kkfileview_version`：例如 `4.4.0` 或 `v4.4.0`

工作流内部会：

1. 规范化版本号并定位上游 tag
2. 拉取 `https://github.com/kekingcn/kkFileView.git`
3. 应用本仓库的 `switch_office_preview_type.patch`
4. 执行 `mvn -B -ntp clean package -DskipTests -f server/pom.xml`
5. 上传 `kkFileView-<version>.jar` 作为 Artifact 供下载

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

- 默认仍然是源码构建模式，只有显式传 `BUILD_MODE=release` 时才会走 jar 下载
- 如果上游 tag 没有公开 jar 资产，`BUILD_MODE=release` 会失败，此时请改回源码构建或传入可访问的 `RELEASE_JAR_URL`
- 版本升级时通常只需要改 `TAG`，或者在 Actions 输入新版本
- 构建过程中会自动拉取上游 `https://github.com/kekingcn/kkFileView.git` 对应 tag 源码并应用本地 patch
