# Docker 构建问题修复说明

## 问题描述

在 GitHub Actions 中使用 QEMU 模拟 loong64 架构构建 Docker 镜像时遇到两个主要问题：

### 问题 1: apt 包版本不可用
```
E: Can't find a source to download version 'X.X.X' of 'package:loongarch64'
```

### 问题 2: GPG 签名验证失败
```
W: GPG error: http://pkg.loongnix.cn/loongnix DaoXiangHu-stable InRelease: At least one invalid signature was encountered.
E: The repository 'http://pkg.loongnix.cn/loongnix DaoXiangHu-stable InRelease' is not signed.
```

## 解决方案

提供了三个版本的 Dockerfile，针对不同的基础镜像和场景：

### 1. `Dockerfile.loong64.openjdk8` ⭐ **强烈推荐**

**基础镜像：** `cr.loongnix.cn/library/openjdk:8-buster`

**优势：**
- ✅ 基础镜像已包含 OpenJDK 8，无需额外安装
- ✅ 完全容错的构建流程
- ✅ 即使 apt 失败也能继续（使用基础镜像自带的工具）
- ✅ 详细的日志输出和错误处理
- ✅ 多仓库镜像自动切换

**改进点：**
- 配置 apt 允许未认证的包
- 渐进式降级策略：先尝试安装所有包，失败后逐个安装
- 每个步骤都有验证和日志
- 尝试多个 LibreOffice 仓库（8.3、8.4、NFS China）
- 增加超时和重试机制

**使用方法：**
```bash
docker buildx build \
  --platform linux/loong64 \
  --build-arg BASE_IMAGE=cr.loongnix.cn/library/openjdk:8-buster \
  -t kkfileview:loong64 \
  -f Dockerfile.loong64.openjdk8 \
  --load .
```

### 2. `Dockerfile.loong64` (适用于 Debian Trixie)

**基础镜像：** `ghcr.io/loong64/debian:trixie-slim`

**特点：**
- 需要从外部仓库安装 OpenJDK 8
- 配置了 loong64 Debian 仓库
- 处理 GPG 签名问题
- 适合需要最新 Debian 环境的场景

**使用方法：**
```bash
docker buildx build \
  --platform linux/loong64 \
  --build-arg BASE_IMAGE=ghcr.io/loong64/debian:trixie-slim \
  -t kkfileview:loong64 \
  -f Dockerfile.loong64 \
  --load .
```

### 3. `Dockerfile.loong64.minimal` (最小化版本)

**特点：**
- 完全跳过失败的 apt 操作
- 支持 wget 或 curl
- 如果工具不可用会跳过 LibreOffice 但容器仍可启动
- 适合调试和测试

**使用方法：**
```bash
docker buildx build \
  --platform linux/loong64 \
  -f Dockerfile.loong64.minimal \
  -t kkfileview:loong64-minimal \
  --load .
```

## GitHub Actions 改进

更新了 `.github/workflows/build-kkfileview-loong64.yml`：

### 新增功能
- ✅ **Dockerfile 选择器**：可以在运行时选择使用哪个 Dockerfile
- ✅ **基础镜像选择器**：支持两种基础镜像
  - `cr.loongnix.cn/library/openjdk:8-buster` (默认，推荐)
  - `ghcr.io/loong64/debian:trixie-slim`
- ✅ `--progress=plain` 显示完整构建日志
- ✅ 更清晰的步骤说明和调试信息

### 使用方法

1. 进入 GitHub 仓库的 **Actions** 标签
2. 选择 **Build kkFileView loong64 image**
3. 点击 **Run workflow**
4. 配置参数：
   - **kkfileview_version**: 例如 `v4.4.0`
   - **build_mode**: `source` 或 `release`
   - **base_image**: 选择基础镜像（推荐 `cr.loongnix.cn/library/openjdk:8-buster`）
   - **dockerfile**: 选择 Dockerfile（推荐 `Dockerfile.loong64.openjdk8`）
   - **image_name**: 输出镜像名称

### 推荐配置

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| base_image | `cr.loongnix.cn/library/openjdk:8-buster` | 已包含 Java 8，最稳定 |
| dockerfile | `Dockerfile.loong64.openjdk8` | 最容错，成功率最高 |
| build_mode | `source` | 从源码构建，最新代码 |

## 测试建议

### 本地测试（如果有 loong64 环境）

```bash
# 1. 测试基础镜像
docker run --rm cr.loongnix.cn/library/openjdk:8-buster bash -c "apt-get update && apt-cache policy wget cpio rpm2cpio"

# 2. 测试构建
docker buildx build --platform linux/loong64 -f Dockerfile.loong64 -t test:loong64 .

# 3. 测试运行
docker run --rm test:loong64 which soffice
```

### GitHub Actions 测试

1. 推送代码到仓库
2. 手动触发 workflow：`Actions` -> `Build kkFileView loong64 image` -> `Run workflow`
3. 查看详细日志以确认哪个仓库成功

## 可用的 Loongnix 仓库

根据提供的信息，以下仓库可用：

1. **容器镜像仓库：**
   - https://cr.loongnix.cn/

2. **软件包仓库：**
   - https://pkg.loongnix.cn/loongnix-server/8.3/AppStream/loongarch64/release/Packages/
   - https://pkg.loongnix.cn/loongnix-server/8.4/AppStream/loongarch64/release/Packages/

3. **备用仓库：**
   - https://updates.os.nfschina.com/NFS4.0/LoongarchOS/RPMS/loongarch64/Releases/AppStream/Packages/

4. **Python 包：**
   - https://pypi.loongnix.cn/loongson/pypi

5. **Docker 发行版：**
   - https://cloud.loongnix.cn/releases/loongarch64abi1/docker/23.0.4/

## 常见问题

### Q: 为什么要分离 RUN 命令？
A: 分离后每个层可以独立缓存，如果某一步失败，可以更容易定位问题。

### Q: 如果所有仓库都失败怎么办？
A: 使用 `Dockerfile.loong64.minimal`，它会跳过 LibreOffice 安装但保持容器可运行。

### Q: QEMU 模拟很慢怎么办？
A: 
- 增加了超时时间到 120 秒
- 考虑使用真实的 loong64 硬件或 CI runner
- 减少不必要的包安装

### Q: 如何验证 LibreOffice 是否安装成功？
A: 构建后运行：
```bash
docker run --rm your-image:tag which soffice
docker run --rm your-image:tag soffice --version
```

## 下一步

1. 先尝试使用更新后的 `Dockerfile.loong64`
2. 如果仍然失败，查看 GitHub Actions 日志确定具体失败点
3. 根据日志选择使用 minimal 或 alternative 版本
4. 考虑联系 Loongnix 社区确认仓库状态

## 参考链接

- Loongnix 官方文档：http://www.loongnix.cn/
- kkFileView 项目：https://github.com/kekingcn/kkFileView
