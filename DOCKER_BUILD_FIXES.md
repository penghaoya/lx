# Docker 构建问题修复说明

## 问题描述

在 GitHub Actions 中使用 QEMU 模拟 loong64 架构构建 Docker 镜像时，apt 包管理器无法找到特定版本的包，导致构建失败。

错误信息：
```
E: Can't find a source to download version 'X.X.X' of 'package:loongarch64'
```

## 解决方案

提供了三个版本的 Dockerfile，按推荐顺序：

### 1. `Dockerfile.loong64` (推荐 - 已更新)

**改进点：**
- 分离了依赖安装和 LibreOffice 安装为两个 RUN 层，便于调试
- 移除了对特定包版本的依赖，让 apt 自动选择可用版本
- 添加了渐进式降级策略：先尝试安装所有包，失败后逐个安装
- 增加了工具可用性检查
- 尝试多个 LibreOffice 仓库镜像（8.3、8.4、NFS China）
- 增加了超时时间（120秒）以适应 QEMU 模拟环境
- 更好的错误处理和日志输出

**使用方法：**
```bash
docker buildx build \
  --platform linux/loong64 \
  --build-arg BASE_IMAGE=cr.loongnix.cn/library/openjdk:8-buster \
  -t kkfileview:loong64 \
  -f Dockerfile.loong64 \
  --load .
```

### 2. `Dockerfile.loong64.minimal` (备选方案)

**特点：**
- 完全容错的构建流程
- 即使 apt 完全失败也能继续构建
- 支持 wget 或 curl 作为下载工具
- 如果 rpm2cpio/cpio 不可用，会跳过 LibreOffice 安装但容器仍可启动
- 适合调试和测试基础镜像功能

**使用方法：**
```bash
docker buildx build \
  --platform linux/loong64 \
  -f Dockerfile.loong64.minimal \
  -t kkfileview:loong64-minimal \
  --load .
```

### 3. `Dockerfile.loong64.alternative` (详细版本)

**特点：**
- 最详细的日志输出
- 每个步骤都有验证
- 适合深度调试

## GitHub Actions 改进

更新了 `.github/workflows/build-kkfileview-loong64.yml`：
- 添加了 `--progress=plain` 以显示完整构建日志
- 添加了构建前的信息输出
- 更清晰的步骤说明

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
