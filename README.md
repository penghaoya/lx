# kkFileView loong64 GitHub Actions 构建

这个仓库用于在 GitHub Actions 上构建可运行于 LoongArch64 服务器的 kkFileView Docker 镜像，并导出为离线部署所需的 tar 文件。

镜像内会安装 kkFileView 文档预览所需的 LibreOffice，并在容器启动时自动探测 `office.home`，避免因路径配置错误导致服务启动失败。

## 工作流能力

- 支持 `release` 模式：直接下载官方发布的 jar，速度更快
- 支持 `source` 模式：从源码编译 jar
- 仅面向 `kkFileView v4.x` 构建
- 固定使用 JDK 8 构建 `v4.x`
- 使用 `docker buildx` + QEMU 构建 `linux/loong64` 镜像
- 自动导出 `docker save` 生成的 tar 包并作为 Actions Artifact 上传

## 使用方法

1. 将当前目录推送到 GitHub 仓库。
2. 打开仓库的 Actions 页面。
3. 可以 push 到 `main` 自动触发，也可以手动运行 `Build kkFileView loong64 image` 工作流。
4. 根据需要填写输入参数：

- `kkfileview_version`：例如 `v4.4.0`
- `build_mode`：`release` 或 `source`，默认建议 `source`
- `base_image`：默认 `cr.loongnix.cn/loongnix-server:8.3`（使用 yum，避免 Debian 系 apt 仓库包缺失问题）
- `image_name`：默认 `kkfileview`

工作流会校验版本号，只有 `v4.x` 会继续执行；如果误填 `v5.x` 或其他版本，会在开始阶段直接失败并提示。

## 产物说明

构建完成后，Artifact 中会生成类似下面的文件：

```text
kkfileview-loong64-4.4.0.tar
```

下载后可拷贝到离线龙芯服务器，再执行：

```bash
docker load -i kkfileview-loong64-4.4.0.tar
docker run -d --name kkfileview -p 8012:8012 -v /usr/share/fonts:/usr/share/fonts kkfileview:loong64-4.4.0
```

如果需要排查启动问题，可以先看容器日志：

```bash
docker logs -f kkfileview
```

## 注意事项

- 上游 `v4.4.0` Release 没有公开 jar 资产，`release` 模式下载失败时会自动回退到源码编译。
- 本仓库当前工作流只处理 `v4.x`，不考虑 `v5.x` 及更高版本。
- 如果默认基础镜像不支持 `linux/loong64`，请在工作流输入中替换为其他支持 LoongArch64 的 JDK 8 镜像。
- kkFileView 常依赖宿主机字体，离线服务器建议挂载 `/usr/share/fonts`。
- 镜像已包含 LibreOffice；如果启动日志仍提示 `找不到office组件`，通常说明镜像不是由当前仓库最新 `Dockerfile.loong64` 构建出来的。
- 默认容器端口为 `8012`，如有冲突可改为 `-p 18012:8012`。
