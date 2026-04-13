# kkFileView loong64 GitHub Actions 构建

这个仓库用于在 GitHub Actions 上构建可运行于 LoongArch64 服务器的 kkFileView Docker 镜像，并导出为离线部署所需的 tar 文件。

## 工作流能力

- 支持 `release` 模式：直接下载官方发布的 jar，速度更快
- 支持 `source` 模式：从源码编译 jar
- 使用 `docker buildx` + QEMU 构建 `linux/loong64` 镜像
- 自动导出 `docker save` 生成的 tar 包并作为 Actions Artifact 上传

## 使用方法

1. 将当前目录推送到 GitHub 仓库。
2. 打开仓库的 Actions 页面。
3. 运行 `Build kkFileView loong64 image` 工作流。
4. 根据需要填写输入参数：

- `kkfileview_version`：例如 `v4.4.0`
- `build_mode`：`release` 或 `source`
- `base_image`：默认 `openjdk:17-jdk-slim`
- `image_name`：默认 `kkfileview`

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

## 注意事项

- 如果默认基础镜像不支持 `linux/loong64`，请在工作流输入中替换为支持 LoongArch64 的 JDK 镜像。
- kkFileView 常依赖宿主机字体，离线服务器建议挂载 `/usr/share/fonts`。
- 默认容器端口为 `8012`，如有冲突可改为 `-p 18012:8012`。# lx
